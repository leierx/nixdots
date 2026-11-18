T=${QS_TEST_DIR:-${XDG_RUNTIME_DIR:-/tmp}/qs-test}
repo=${QS_TEST_REPO:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}
host=${QS_TEST_HOST:-$(uname -n)}
src=$repo/modules/features/hyprland/quickshell

usage() {
  cat << EOF
usage: qs-test COMMAND

  up                    build the checkout's Hyprland config and shell, start them in $T
  down                  stop the session and remove it and the test shell's state
  status                whether a session is up
  sync                  copy the checkout's QML in, restart qs, print its warnings
  restart               restart qs, print its warnings
  lint                  qmllint the checkout's shell, as nix flake check does

  ipc ARGS...           qs ipc call ARGS (panels open apps, notifications count, ...)
  key COMBO...          press keys in turn (ctrl+n, super+d, shift+Tab, Escape)
  type TEXT             type TEXT into the focused surface
  pointer X Y           put the pointer at X Y in layout coordinates (hover)
  move DX DY            move the pointer by DX DY
  click [BUTTON] [X Y]  click left (or right, middle), at X Y if given
  press|release BUTTON  hold or let go of a button
  drag X Y DX DY [MS]   press left at X Y, glide DX DY over MS (300) ms, release
  wheel STEPS [horizontal]  scroll STEPS notches, positive down or right
  layers                the layer surfaces up, by namespace and monitor
  shot [NAME] [WHERE]   screenshot of everything, a monitor, or "x,y wxh"; prints its path
  monitor add NAME [MODE] [SCALE] [POSITION]   plug a monitor in (1920x1080, 1, auto-right)
  monitor remove NAME   unplug it
  monitors              the monitors
  output MODE [SCALE]   change the first monitor's mode (2560x1440 1.5)
  spawn CMD...          start CMD in the session, detached (output in spawn.log)
  tray [log]            add a test tray item with submenus (tests/tray.qml), or show what it was told
  x CMD...              run CMD in the session (notify-send, hyprctl, ...)

  log                   qs's whole log
  hyprlog               Hyprland's log
  problems              qs's warnings and errors, less the expected ones
  actions               what the session tried to run on the machine (power, systemd-run, ...)

env: QS_TEST_DIR (session dir), QS_TEST_HOST (host whose config is built, $host),
     QS_TEST_REPO (checkout), QS_TEST_MONITORS (NAME:MODE:SCALE ..., DP-1:1920x1080:1)
EOF
}

die() {
  echo "qs-test: $*" >&2
  exit 1
}

running() { [ -s "$T/hyprland.pid" ] && kill -0 "$(cat "$T/hyprland.pid")" 2> /dev/null; }
need_up() { running || die "no session in $T; run qs-test up"; }

enter() {
  XDG_RUNTIME_DIR=$(cat "$T/runtime")
  WAYLAND_DISPLAY=$(cat "$T/display")
  HYPRLAND_INSTANCE_SIGNATURE=$(cat "$T/signature")
  DBUS_SESSION_BUS_ADDRESS=$(cat "$T/bus")
  XDG_CONFIG_HOME=$T/cfg
  XDG_CURRENT_DESKTOP=Hyprland
  PATH=$T/bin:$PATH
  HC=$(cat "$T/build")/hyprland/bin/hyprctl
  export XDG_RUNTIME_DIR WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS XDG_CONFIG_HOME XDG_CURRENT_DESKTOP PATH
  unset DISPLAY SWAYSOCK
}

# By config path, since setsid may fork and leave no pid to remember.
testqs() {
  (
    enter
    qs list --all 2> /dev/null | awk -v path="$T/shell/shell.qml" '/Process ID/ { pid = $3 } /Config path/ && $3 == path { print pid }'
  )
}

problems() {
  grep -E 'WARN|ERROR' "$T/qs.log" | grep -vE 'UPower|qt\.qpa\.services|Could not register app ID|qt\.qpa\.wayland\.textinput' || true
}

start_qs() {
  (
    enter
    setsid qs -p "$T/shell" > "$T/qs.log" 2>&1 < /dev/null &
  )
  for _ in $(seq 100); do
    grep -qE 'Configuration Loaded|Failed to load' "$T/qs.log" && break
    sleep 0.1
  done
  problems
  grep -q 'Configuration Loaded' "$T/qs.log" || die "the shell did not load, see qs-test log"
}

stop_qs() {
  local pid
  for pid in $(testqs); do kill "$pid"; done
  for _ in $(seq 50); do
    [ -z "$(testqs)" ] && return
    sleep 0.1
  done
}

# path:, since a git flake leaves untracked files out
build() {
  nix build --no-link --print-out-paths --impure --expr "
    let
      system = (builtins.getFlake \"path:$repo\").nixosConfigurations.$host;
      home = system.config.home-manager.users.$USER;
    in
    system.pkgs.linkFarm \"qs-test-$host\" {
      shell = home.programs.quickshell.configs.shell;
      hyprland = system.config.programs.hyprland.package;
      \"hyprland.lua\" = home.xdg.configFile.\"hypr/hyprland.lua\".source;
      hyprsplit = home.xdg.configFile.\"hypr/hyprsplit\".source;
      hyprpaper = home.services.hyprpaper.package;
      \"hyprpaper.conf\" = home.xdg.configFile.\"hypr/hyprpaper.conf\".source;
    }"
}

# nix/ and the weather icons exist only in the built copy.
sync_source() {
  local keep=$T/keep
  rm -rf "$keep" && mkdir -p "$keep"
  mv "$T/shell/nix" "$keep/nix"
  mv "$T/shell/weather/icons" "$keep/icons"
  rm -rf "$T/shell"
  cp -r "$src" "$T/shell"
  chmod -R u+w "$T/shell"
  mv "$keep/nix" "$T/shell/nix"
  mv "$keep/icons" "$T/shell/weather/icons"
}

# Nothing in the session may reach the real machine: these log what would have run instead.
fakes() {
  local config=${XDG_CONFIG_HOME:-$HOME/.config} cliphist entry
  mkdir -p "$T/bin" "$T/cfg/hyprmoncfg"
  hyprmoncfg status --json > "$T/status.json" 2> /dev/null || echo '{"profiles":[]}' > "$T/status.json"
  : > "$T/actions.log"

  cat > "$T/bin/hyprctl" << EOF
#!/bin/sh
case "\$*" in *'hl.dsp.exit()'*) echo "hyprctl \$*" >> "$T/actions.log"; exit ;; esac
case "\$1" in dispatch | reload | keyword | eval) echo "hyprctl \$*" >> "$T/actions.log" ;; esac
exec "$1/hyprland/bin/hyprctl" "\$@"
EOF
  cat > "$T/bin/hyprmoncfg" << EOF
#!/bin/sh
case "\$1" in status) cat "$T/status.json" ;; *) echo "hyprmoncfg \$*" >> "$T/actions.log" ;; esac
EOF
  # A scope is how the shell starts apps, so those still open in the session.
  cat > "$T/bin/systemd-run" << EOF
#!/bin/sh
echo "systemd-run \$*" >> "$T/actions.log"
case " \$* " in *' --scope '*) ;; *) exit ;; esac
while [ "\${1#-}" != "\$1" ]; do shift; done
case "\$1" in nixpkgs-run | xdg-open) exit ;; esac
exec "\$@"
EOF
  for entry in systemctl loginctl pw-play xdg-open nixpkgs-run; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/actions.log"\n' "$entry" "$T" > "$T/bin/$entry"
  done
  cliphist=$(command -v cliphist || true)
  if [ -n "$cliphist" ]; then
    [ -f "$HOME/.cache/cliphist/db" ] && cp "$HOME/.cache/cliphist/db" "$T/clip.db"
    printf '#!/bin/sh\nexec %s -db-path "%s/clip.db" "$@"\n' "$cliphist" "$T" > "$T/bin/cliphist"
  fi
  chmod +x "$T/bin/"*

  for entry in "$config"/*; do
    case $(basename "$entry") in hypr | hyprmoncfg) ;; *) ln -sfn "$entry" "$T/cfg/" ;; esac
  done
  [ -e "$config/hyprmoncfg/profiles" ] && ln -sfn "$config/hyprmoncfg/profiles" "$T/cfg/hyprmoncfg/profiles"
  return 0
}

# The host's own config, less what starts with the session and the monitors, which are the test's.
hypr_config() {
  local hypr=$T/cfg/hypr
  mkdir -p "$hypr"
  cp "$1/hyprland.lua" "$hypr/host.lua"
  cp -r "$1/hyprsplit" "$hypr/hyprsplit"
  cp "$1/hyprpaper.conf" "$hypr/hyprpaper.conf"
  chmod -R u+w "$hypr"
  : > "$hypr/monitors.lua"
  cat > "$hypr/hyprland.lua" << EOF
local on, monitor = hl.on, hl.monitor
hl.on = function(event, fn) if event ~= "hyprland.start" then return on(event, fn) end end
hl.monitor = function() end
dofile("$hypr/host.lua")
hl.on, hl.monitor = on, monitor
hl.config({ misc = { disable_watchdog_warning = true } })
dofile("$hypr/monitors.lua")
EOF
}

monitor_rule() {
  printf 'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s })\n' "$1" "${2:-1920x1080}" "${4:-auto-right}" "${3:-1}"
}

monitor_add() {
  local rule
  rule=$(monitor_rule "$@")
  grep -v "output = \"$1\"" "$T/cfg/hypr/monitors.lua" > "$T/monitors.tmp" || true
  echo "$rule" >> "$T/monitors.tmp"
  mv "$T/monitors.tmp" "$T/cfg/hypr/monitors.lua"
  "$HC" eval "$rule" > /dev/null
  "$HC" monitors all -j | jq -e --arg name "$1" 'any(.name == $name)' > /dev/null || "$HC" output create headless "$1" > /dev/null
}

monitor_remove() {
  grep -v "output = \"$1\"" "$T/cfg/hypr/monitors.lua" > "$T/monitors.tmp" || true
  mv "$T/monitors.tmp" "$T/cfg/hypr/monitors.lua"
  "$HC" output remove "$1" > /dev/null
}

# Monitor ids go to the lowest one free, so a placeholder keeps WAYLAND-1's id 0 for the first test monitor.
monitors_up() {
  local spec name mode scale first=1
  "$HC" output create headless qst-placeholder > /dev/null
  "$HC" output remove WAYLAND-1 > /dev/null
  for spec in ${QS_TEST_MONITORS:-DP-1:1920x1080:1}; do
    IFS=: read -r name mode scale <<< "$spec"
    monitor_add "$name" "$mode" "$scale" "$([ $first = 1 ] && echo 0x0 || echo auto-right)"
    if [ $first = 1 ]; then
      first=0
      "$HC" output remove qst-placeholder > /dev/null
    fi
  done
}

up() {
  if running; then
    echo "up in $T"
    return
  fi
  local build runtime
  build=$(build)
  mkdir -p "$T/shots" "$T/labwc"
  rm -rf "$T/shell" "$T/cfg" "$T/display" "$T/signature"
  echo "$build" > "$T/build"
  cp -rL "$build/shell" "$T/shell"
  chmod -R u+w "$T/shell"
  fakes "$build"
  hypr_config "$build"
  # Hyprland's sockets go in here, and their paths must stay under 108 bytes.
  runtime=$(mktemp -d -p "${XDG_RUNTIME_DIR:-/tmp}" qs.XXX)
  echo "$runtime" > "$T/runtime"

  # labwc only lends Hyprland a GPU: headless, it offers the xdg_wm_base 6 Hyprland needs to nest.
  # libseat pointed at no seatd keeps Hyprland off DRM and logind, so it never touches the real session.
  cat > "$T/run.sh" << EOF
#!/bin/sh
echo \$DBUS_SESSION_BUS_ADDRESS > "$T/bus"
export XDG_RUNTIME_DIR="$runtime" XDG_CONFIG_HOME="$T/cfg" PATH="$T/bin:\$PATH"
export LIBSEAT_BACKEND=seatd SEATD_SOCK="$runtime/no-seatd"
unset WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE SWAYSOCK
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 labwc -C "$T/labwc" > "$T/labwc.log" 2>&1 &
echo \$! > "$T/labwc.pid"
for _ in \$(seq 100); do [ -S "$runtime/wayland-0" ] && break; sleep 0.1; done
export WAYLAND_DISPLAY=wayland-0 XDG_CURRENT_DESKTOP=Hyprland
export HYPRLAND_NO_SD_VARS=1 HYPRLAND_NO_SD_NOTIFY=1 HYPRLAND_NO_SD_TARGET=1 HYPRLAND_NO_CRASHREPORTER=1
echo \$\$ > "$T/hyprland.pid"
exec "$build/hyprland/bin/Hyprland"
EOF
  chmod +x "$T/run.sh"
  setsid dbus-run-session -- "$T/run.sh" > "$T/hyprland.log" 2>&1 < /dev/null &
  local instance=""
  for _ in $(seq 150); do
    instance=$(XDG_RUNTIME_DIR=$runtime "$build/hyprland/bin/hyprctl" instances -j 2> /dev/null | jq -r '.[0] | select(.) | "\(.instance) \(.wl_socket)"' 2> /dev/null || true)
    [ -n "$instance" ] && break
    sleep 0.1
  done
  [ -n "$instance" ] || die "Hyprland did not start, see $T/hyprland.log and $T/labwc.log"
  echo "${instance% *}" > "$T/signature"
  echo "${instance#* }" > "$T/display"

  enter
  monitors_up
  XKB_DEFAULT_LAYOUT=$("$HC" getoption input:kb_layout -j | jq -r .str) \
    XKB_DEFAULT_VARIANT=$("$HC" getoption input:kb_variant -j | jq -r .str) \
    setsid qs-input serve "$XDG_RUNTIME_DIR/input" > "$T/input.log" 2>&1 < /dev/null &
  setsid "$build/hyprpaper/bin/hyprpaper" > "$T/hyprpaper.log" 2>&1 < /dev/null &
  for _ in $(seq 50); do
    [ -S "$XDG_RUNTIME_DIR/input" ] && break
    sleep 0.1
  done
  [ -S "$XDG_RUNTIME_DIR/input" ] || die "qs-input did not start, see $T/input.log"
  start_qs
  echo "up in $T"
}

down() {
  local bus="" runtime="" pid id
  [ -s "$T/runtime" ] && runtime=$(cat "$T/runtime")
  [ -s "$T/bus" ] && bus=$(cat "$T/bus")
  [ -s "$T/runtime" ] && [ -s "$T/display" ] && stop_qs
  if running; then kill "$(cat "$T/hyprland.pid")"; fi
  # Whatever the session started outlives it, portals reparented to pid 1 among them.
  for pid in /proc/[0-9]*; do
    pid=${pid#/proc/}
    [ "$pid" = $$ ] && continue
    tr '\0' '\n' 2> /dev/null < "/proc/$pid/environ" |
      grep -qxF -e "DBUS_SESSION_BUS_ADDRESS=${bus:-none}" -e "XDG_RUNTIME_DIR=${runtime:-none}" &&
      kill "$pid" 2> /dev/null
  done
  # Quickshell keys its dirs by config path, so these are the test shell's own.
  id=$(grep -o 'Shell ID: "[0-9a-f]*' "$T/qs.log" 2> /dev/null | head -1 | cut -d'"' -f2 || true)
  if [ -n "$id" ]; then
    rm -rf "$HOME/.local/state/quickshell/by-shell/$id" "$HOME/.cache/quickshell/by-shell/$id"
  fi
  [ -n "$runtime" ] && rm -rf "$runtime"
  rm -rf "$T"
  echo down
}

input() {
  enter
  qs-input "$XDG_RUNTIME_DIR/input" "$@"
}

# Absolute motion from the virtual pointer, which hovers where a warp (hl.dsp.cursor.move) may not.
pointer() {
  local box
  enter
  box=$("$HC" monitors -j | jq -r --argjson x "$1" --argjson y "$2" '
    map(if .transform % 2 == 1 then [.x, .y, .height / .scale, .width / .scale] else [.x, .y, .width / .scale, .height / .scale] end)
    | (map(.[0]) | min) as $left | (map(.[1]) | min) as $top
    | "\($x - $left) \($y - $top) \(map(.[0] + .[2]) | max | . - $left | round) \(map(.[1] + .[3]) | max | . - $top | round)"')
  # shellcheck disable=SC2086
  input to $box
}

shot() {
  local name=${1:-shot} file
  file=$T/shots/$(printf '%03d' "$(find "$T/shots" -name '*.png' | wc -l)")-$name.png
  enter
  if [ -z "${2:-}" ]; then
    grim "$file"
  elif "$HC" monitors -j | jq -e --arg name "$2" 'any(.name == $name)' > /dev/null; then
    grim -o "$2" "$file"
  else
    grim -g "$2" "$file"
  fi
  echo "$file"
}

cmd=${1:-help}
shift || true
case $cmd in
  up) up ;;
  down) down ;;
  status) if running; then echo "up in $T, qs $(testqs)"; else echo down; fi ;;
  sync) need_up; stop_qs; sync_source; start_qs ;;
  restart) need_up; stop_qs; start_qs ;;
  lint) qs-lint "$(readlink -f "$(build)/shell")" ;;
  ipc) need_up; enter; timeout 5 qs ipc -p "$T/shell" call "$@" ;;
  key) need_up; input key "$@" ;;
  type) need_up; input type "$*" ;;
  pointer) need_up; pointer "$1" "$2" ;;
  move) need_up; input move "$1" "$2" ;;
  click)
    need_up
    button=left
    case ${1:-} in left | right | middle) button=$1; shift ;; esac
    [ $# -ge 2 ] && pointer "$1" "$2"
    input click "$button"
    ;;
  press | release) need_up; input "$cmd" "${1:-left}" ;;
  drag)
    need_up
    pointer "$1" "$2"
    input press left
    input glide "$3" "$4" "${5:-300}"
    input release left
    ;;
  wheel) need_up; input wheel "$@" ;;
  layers) need_up; enter; "$HC" layers -j | jq -r 'to_entries[] | .key as $m | .value.levels[][] | "\($m) \(.namespace)"' ;;
  shot) need_up; shot "$@" ;;
  monitor)
    need_up
    enter
    case ${1:-} in
      add) shift; monitor_add "$@" ;;
      remove) monitor_remove "$2" ;;
      *) die "monitor add|remove NAME" ;;
    esac
    ;;
  monitors) need_up; enter; "$HC" monitors -j | jq -r '.[] | "\(.name) id \(.id) \(.width)x\(.height) scale \(.scale) at \(.x)x\(.y)"' ;;
  output)
    need_up
    enter
    monitor_add "$("$HC" monitors -j | jq -r 'min_by(.id).name')" "$1" "${2:-1}" 0x0
    ;;
  spawn) need_up; enter; setsid "$@" >> "$T/spawn.log" 2>&1 < /dev/null & ;;
  tray)
    need_up
    if [ "${1:-}" = log ]; then
      grep -o 'qml: .*' "$T/tray.log"
    else
      enter
      [ -s "$T/tray.pid" ] && kill "$(cat "$T/tray.pid")" 2> /dev/null || true
      qs-tray > "$T/tray.log" 2>&1 < /dev/null &
      echo $! > "$T/tray.pid"
    fi
    ;;
  x) need_up; enter; exec "$@" ;;
  log) cat "$T/qs.log" ;;
  hyprlog) enter; cat "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" ;;
  problems) problems ;;
  actions) cat "$T/actions.log" ;;
  help | -h | --help) usage ;;
  *) usage >&2; exit 1 ;;
esac
