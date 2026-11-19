T=${QS_TEST_DIR:-${XDG_RUNTIME_DIR:-/tmp}/qs-test}
repo=${QS_TEST_REPO:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}
host=${QS_TEST_HOST:-$(uname -n)}
src=$repo/modules/features/hyprland/quickshell
tests=$repo/modules/features/hyprland/tests
self=$(readlink -f "$0")

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
  state [JQ]            what the shell sees (tests/Probe.qml) with Hyprland's layers and monitors, through JQ
  wait JQ [SECONDS]     until JQ holds on the state (5 s), or fail and print it
  stays JQ [SECONDS]    fail if JQ stops holding within SECONDS (1)
  reset                 QS_TEST_MONITORS again, ids from 0, no windows, and a fresh qs without saved state
  case NAME             a test's next case: print it and reset
  run [FILE...]         copy the checkout's QML in, run tests (tests/scenarios/*.sh) in the session, qst on PATH
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
  monitor disable NAME  turn it off as a hyprmoncfg profile does; enable turns it back on
  monitors              the monitors, disabled ones too
  focus NAME            focus a monitor
  output MODE [SCALE]   change the first monitor's mode (2560x1440 1.5)
  pipewire start|stop|restart   the session's own sound server (tests/pipewire.conf)
  backlight NAME VALUE [MAX]    set a fake backlight (max 100) and announce it as udev does; NAME remove unplugs it
  camera open|close NAME [DEV]  a process named NAME holding a fake camera (video0) open; add|remove DEV
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
  # Quickshell warns of a monitor removed it never tracked: FALLBACK, or one a refresh dropped in a burst; the session has no PipeWire; with no output at all, Qt moves
  # windows to a placeholder screen for a moment, and each warns before it is gone or placed.
  awk '/creating placeholder screen/ { held = 1; next } held && /Layershell screen does not correspond/ { next } { held = 0; print }' "$T/qs.log" |
    grep -E 'WARN|ERROR' | grep -vE 'UPower|qt\.qpa\.services|Could not register app ID|qt\.qpa\.wayland\.textinput|removal for monitor ".*" which was not previously tracked|Failed to connect pipewire context' || true
  if running && [ -s "$T/display" ] && ! alive; then echo "qs is not running: it crashed or failed to load"; fi
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
  # Always a battery, so the bar shows everything it can on any host; `ipc bar realBattery` drops it. The sound server is the session's own.
  (enter && timeout 5 qs ipc -p "$T/shell" call bar fakeBattery 76 false > /dev/null) || echo "qs-test: could not fake a battery" >&2
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
  install_probe
}

# The test's own window into the shell, in its copy only.
install_probe() {
  mkdir -p "$T/shell/probe"
  cp "$tests/Probe.qml" "$T/shell/probe/Probe.qml"
  sed -i -e 's/^import Quickshell$/&\nimport qs.probe/' -e '$ s/^}$/\n  Probe {}\n}/' "$T/shell/shell.qml"
  grep -q 'Probe {}' "$T/shell/shell.qml" || die "could not add the probe to shell.qml"
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
  # systemctl keeps the state of the units it starts and stops, as the shell reads it back.
  cat > "$T/bin/systemctl" << EOF
#!/bin/sh
[ "\$1" = --user ] && shift
case "\$1" in
  is-active) if [ -e "$T/units/\$2" ]; then echo active; else echo inactive; exit 3; fi ;;
  start) echo "systemctl --user \$*" >> "$T/actions.log"; mkdir -p "$T/units"; touch "$T/units/\$2" ;;
  stop) echo "systemctl --user \$*" >> "$T/actions.log"; rm -f "$T/units/\$2" ;;
  *) echo "systemctl \$*" >> "$T/actions.log" ;;
esac
EOF
  # The real watchers, on a fake /dev and sysfs; udevadm replays what qst backlight appends.
  mkdir -p "$T/dev" "$T/backlight"
  : > "$T/dev/video0"
  : > "$T/udev"
  printf '#!/bin/sh\nexec tail -n0 -F "%s/udev"\n' "$T" > "$T/bin/udevadm"
  printf '#!/bin/sh\nexec %s "%s/backlight"\n' "$(command -v backlight-watch)" "$T" > "$T/bin/backlight-watch"
  printf '#!/bin/sh\nexec %s "%s/dev"\n' "$(command -v camera-users)" "$T" > "$T/bin/camera-users"
  for entry in loginctl pw-play xdg-open nixpkgs-run; do
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

# The session's own sound server (tests/pipewire.conf): null devices, no hardware, no system bus,
# its state in the session, and the Speakers at 64 %.
pw_start() {
  local pw=$T/pw
  mkdir -p "$pw/cfg/wireplumber/wireplumber.conf.d" "$pw/state"
  cp "$tests/wireplumber.conf" "$pw/cfg/wireplumber/wireplumber.conf.d/qs-test.conf"
  (
    enter
    export XDG_CONFIG_HOME=$pw/cfg XDG_STATE_HOME=$pw/state DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent
    setsid pipewire -c "$tests/pipewire.conf" > "$T/pipewire.log" 2>&1 < /dev/null &
    echo $! > "$T/pipewire.pid"
    for _ in $(seq 50); do
      [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break
      sleep 0.1
    done
    setsid wireplumber > "$T/wireplumber.log" 2>&1 < /dev/null &
    echo $! > "$T/wireplumber.pid"
  )
  (
    enter
    for _ in $(seq 100); do
      wpctl inspect @DEFAULT_AUDIO_SINK@ > /dev/null 2>&1 && wpctl inspect @DEFAULT_AUDIO_SOURCE@ > /dev/null 2>&1 && break
      sleep 0.1
    done
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.64
  ) || die "PipeWire did not start, see $T/pipewire.log and $T/wireplumber.log"
}

pw_stop() {
  local name pid
  for name in wireplumber pipewire; do
    [ -s "$T/$name.pid" ] || continue
    pid=$(cat "$T/$name.pid")
    kill "$pid" 2> /dev/null || true
    for _ in $(seq 50); do
      kill -0 "$pid" 2> /dev/null || break
      sleep 0.1
    done
    rm -f "$T/$name.pid"
  done
}

# Each fresh: wireplumber's remembered defaults and volumes go too.
pw_reset() {
  pw_stop
  rm -rf "$T/pw/state"
  pw_start
}

# A backlight's level, as the kernel would set it and announce it.
backlight() {
  local dir=$T/backlight/$1 event
  if [ "${2:-}" = remove ]; then
    rm -rf "$dir"
    event=remove
  else
    mkdir -p "$dir"
    printf '%s\n' "${3:-100}" > "$dir/max_brightness"
    printf '%s\n' "$2" > "$dir/brightness"
    printf '%s\n' "$2" > "$dir/actual_brightness"
    event=change
  fi
  local filter tries=0
  filter=$(if [ "$event" = remove ]; then echo ".brightness[\"$1\"] == null"; else echo ".brightness[\"$1\"].brightness == $2"; fi)
  # Until the shell has it: udevadm may not be listening yet, as at a real boot.
  while :; do
    printf 'UDEV  [%s] %-8s /devices/qs-test/backlight/%s (backlight)\n' "$(date +%s.%N)" "$event" "$1" >> "$T/udev"
    for _ in 1 2 3 4 5; do
      snapshot | jq -e "$filter" > /dev/null && return
      sleep 0.1
    done
    tries=$((tries + 1))
    [ $tries -lt 10 ] || die "the shell never saw backlight $1 $event"
  done
}

# A process named NAME holding a fake camera open, as an app streaming from it would.
camera() {
  local name=${2:-}
  mkdir -p "$T/holders"
  case $1 in
    open)
      [ -e "$T/dev/${3:-video0}" ] || die "no camera ${3:-video0}"
      # shellcheck disable=SC2016
      setsid bash -c 'exec 3< "$1"; printf %s "$2" > /proc/$$/comm; while :; do sleep 3600 3<&-; done' _ "$T/dev/${3:-video0}" "$name" < /dev/null > /dev/null 2>&1 &
      echo $! > "$T/holders/$name"
      ;;
    close)
      [ -s "$T/holders/$name" ] || die "no $name holds a camera"
      kill -- -"$(cat "$T/holders/$name")" 2> /dev/null || true
      rm -f "$T/holders/$name"
      ;;
    add) : > "$T/dev/$name" ;;
    remove) rm -f "$T/dev/$name" ;;
    *) die "camera open|close NAME [DEVICE], or add|remove DEVICE" ;;
  esac
}

camera_reset() {
  local holder
  for holder in "$T"/holders/*; do
    [ -s "$holder" ] && kill -- -"$(cat "$holder")" 2> /dev/null
    rm -f "$holder"
  done
  find "$T/dev" -name 'video*' ! -name video0 -delete
  : > "$T/dev/video0"
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
  printf 'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s, disabled = false })\n' "$1" "${2:-1920x1080}" "${4:-auto-right}" "${3:-1}"
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
  rm -f "$T/disabled/$1"
  "$HC" output remove "$1" > /dev/null
}

# As a hyprmoncfg profile turns one off: the output stays, Wayland's wl_output goes.
monitor_disable() {
  local rule
  rule=$(grep "output = \"$1\"" "$T/cfg/hypr/monitors.lua") || die "no monitor $1"
  mkdir -p "$T/disabled"
  case $rule in *"disabled = true"*) ;; *) echo "$rule" > "$T/disabled/$1" ;; esac
  rule=$(printf 'hl.monitor({ output = "%s", disabled = true })' "$1")
  grep -v "output = \"$1\"" "$T/cfg/hypr/monitors.lua" > "$T/monitors.tmp" || true
  echo "$rule" >> "$T/monitors.tmp"
  mv "$T/monitors.tmp" "$T/cfg/hypr/monitors.lua"
  "$HC" eval "$rule" > /dev/null
}

monitor_enable() {
  local rule
  [ -s "$T/disabled/$1" ] || die "$1 is not disabled"
  rule=$(cat "$T/disabled/$1")
  rm "$T/disabled/$1"
  grep -v "output = \"$1\"" "$T/cfg/hypr/monitors.lua" > "$T/monitors.tmp" || true
  echo "$rule" >> "$T/monitors.tmp"
  mv "$T/monitors.tmp" "$T/cfg/hypr/monitors.lua"
  "$HC" eval "$rule" > /dev/null
}

monitor_id() { "$HC" monitors all -j | jq -r --arg name "$1" '.[] | select(.name == $name) | .id'; }

# A headless output of a name Hyprland has never seen, which takes the lowest id free.
fresh_output() {
  local name
  name=qst-hold-$(date +%s%N)
  "$HC" output create headless "$name" > /dev/null
  echo "$name"
}

# Fresh outputs until one takes id $1; the others go again.
hold_id() {
  local name others=() tries=0
  while :; do
    name=$(fresh_output)
    [ "$(monitor_id "$name")" -ge "$1" ] && break
    others+=("$name")
    tries=$((tries + 1))
    [ $tries -lt 32 ] || die "could not hold monitor id $1"
  done
  for other in "${others[@]}"; do "$HC" output remove "$other" > /dev/null; done
  echo "$name"
}

# Exactly QS_TEST_MONITORS, ids from 0 in order. Hyprland gives a name back the id it last had
# unless a monitor holds it, and otherwise the lowest one free; one stays up throughout, or
# Hyprland stands its FALLBACK in.
monitors_reset() {
  local specs spec name mode scale position i=0 id held hold
  read -ra specs <<< "${QS_TEST_MONITORS:-DP-1:1920x1080:1}"
  held=$(hold_id ${#specs[@]})
  for name in $("$HC" monitors all -j | jq -r --arg held "$held" '.[] | select(.name != $held and .name != "FALLBACK") | .name'); do
    "$HC" output remove "$name" > /dev/null
  done
  : > "$T/cfg/hypr/monitors.lua"
  rm -rf "$T/disabled"
  for spec in "${specs[@]}"; do
    IFS=: read -r name mode scale <<< "$spec"
    position=$([ $i = 0 ] && echo 0x0 || echo auto-right)
    monitor_add "$name" "$mode" "$scale" "$position"
    id=$(monitor_id "$name")
    if [ "$id" != $i ]; then
      "$HC" output remove "$name" > /dev/null
      hold=$(hold_id "$id")
      monitor_add "$name" "$mode" "$scale" "$position"
      "$HC" output remove "$hold" > /dev/null
      [ "$(monitor_id "$name")" = $i ] || die "could not give $name monitor id $i"
    fi
    i=$((i + 1))
  done
  "$HC" output remove "$held" > /dev/null
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
  install_probe
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
  monitors_reset
  pw_start
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

alive() { [ -n "$(testqs)" ]; }

# The probe's view of the shell, plus Hyprland's layers ("DP-1 quickshell:bar") and monitors.
snapshot() {
  local probe layers monitors
  enter
  alive || die "qs is not running: it crashed or failed to load, see qs-test log"
  probe=$(timeout 5 qs ipc -p "$T/shell" call probe state) || die "the probe did not answer, see qs-test log"
  layers=$("$HC" layers -j | jq -c '[to_entries[] | .key as $m | .value.levels[][] | "\($m) \(.namespace)"]')
  monitors=$("$HC" monitors all -j | jq -c 'map({ name, id, disabled, x, y, width, height, scale, focused })')
  jq -c --argjson layers "$layers" --argjson hypr "$monitors" '. + { layers: $layers, hypr: $hypr }' <<< "$probe"
}

state() { snapshot | jq -c "${1:-.}"; }

# Until FILTER holds, as jq -e reads it, or fails after SECONDS.
wait_for() {
  local filter=$1 deadline json
  deadline=$(($(date +%s%N) / 1000000 + ${2:-5} * 1000))
  while :; do
    json=$(snapshot)
    jq -e "$filter" <<< "$json" > /dev/null 2>&1 && return
    if [ "$(($(date +%s%N) / 1000000))" -ge "$deadline" ]; then
      echo "qs-test: timed out after ${2:-5} s waiting for: $filter" >&2
      jq -c "del(.workspaces)" <<< "$json" >&2
      exit 1
    fi
    sleep 0.1
  done
}

# FILTER holds throughout SECONDS (1): what should stay as it is.
stays() {
  local filter=$1 deadline json
  deadline=$(($(date +%s%N) / 1000000 + $(awk -v s="${2:-1}" 'BEGIN { print int(s * 1000) }')))
  while [ "$(($(date +%s%N) / 1000000))" -lt "$deadline" ]; do
    json=$(snapshot)
    if ! jq -e "$filter" <<< "$json" > /dev/null 2>&1; then
      echo "qs-test: no longer holds: $filter" >&2
      jq -c "del(.workspaces)" <<< "$json" >&2
      exit 1
    fi
    sleep 0.1
  done
}

# A fresh start for a test: QS_TEST_MONITORS again, the focus on the first, and a new qs with no state.
reset() {
  local id pid
  enter
  [ -s "$T/tray.pid" ] && kill "$(cat "$T/tray.pid")" 2> /dev/null || true
  rm -f "$T/tray.pid"
  for pid in $("$HC" clients -j | jq -r '.[].pid'); do kill "$pid" 2> /dev/null || true; done
  stop_qs
  pw_reset
  camera_reset
  rm -rf "$T/units" "$T/backlight"
  mkdir -p "$T/backlight"
  monitors_reset
  "$HC" dispatch "hl.dsp.focus({ monitor = \"$("$HC" monitors -j | jq -r 'min_by(.id).name')\" })" > /dev/null
  id=$(grep -o 'Shell ID: "[0-9a-f]*' "$T/qs.log" 2> /dev/null | head -1 | cut -d'"' -f2 || true)
  [ -n "$id" ] && rm -rf "$HOME/.local/state/quickshell/by-shell/$id"
  : > "$T/actions.log"
  start_qs > /dev/null
  problems
  wait_for "(.screens | length) == ($("$HC" monitors -j | jq length)) and (.layers | map(select(endswith(\" quickshell:bar\"))) | length) == (.screens | length)" 10
}

# Each test file runs in the session, calling qst; one that fails stops at its first failure.
run_tests() {
  local file name failed=0
  mkdir -p "$T/tests"
  ln -sfn "$self" "$T/bin/qst"
  export QS_TEST_DIR=$T QS_TEST_REPO=$repo QS_TEST_HOST=$host
  [ $# -gt 0 ] || set -- "$tests"/scenarios/*.sh
  stop_qs
  sync_source
  start_qs > /dev/null
  for file in "$@"; do
    name=$(basename "$file" .sh)
    if (enter && bash -euo pipefail "$file") > "$T/tests/$name.log" 2>&1; then
      echo "ok   $name ($(grep -c '^== ' "$T/tests/$name.log") cases)"
    else
      failed=1
      echo "FAIL $name, in: $(grep '^== ' "$T/tests/$name.log" | tail -1 | cut -c4-)"
      grep -v '^== ' "$T/tests/$name.log" | tail -15 | sed 's/^/     /'
    fi
  done
  return $failed
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
  state) need_up; state "$@" ;;
  wait) need_up; wait_for "$@" ;;
  stays) need_up; stays "$@" ;;
  reset) need_up; reset ;;
  case) need_up; echo "== $*"; reset ;;
  run) need_up; run_tests "$@" ;;
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
      disable) monitor_disable "$2" ;;
      enable) monitor_enable "$2" ;;
      *) die "monitor add|remove|disable|enable NAME" ;;
    esac
    ;;
  monitors) need_up; enter; "$HC" monitors all -j | jq -r '.[] | "\(.name) id \(.id) \(.width)x\(.height) scale \(.scale) at \(.x)x\(.y)\(if .disabled then " disabled" else "" end)\(if .focused then " focused" else "" end)"' ;;
  focus) need_up; enter; "$HC" dispatch "hl.dsp.focus({ monitor = \"$1\" })" > /dev/null ;;
  output)
    need_up
    enter
    monitor_add "$("$HC" monitors -j | jq -r 'min_by(.id).name')" "$1" "${2:-1}" 0x0
    ;;
  pipewire)
    need_up
    case ${1:-} in
      start) pw_start ;;
      stop) pw_stop ;;
      restart) pw_stop; pw_start ;;
      *) die "pipewire start|stop|restart" ;;
    esac
    ;;
  backlight) need_up; [ $# -ge 2 ] || die "backlight NAME VALUE [MAX], or NAME remove"; backlight "$@" ;;
  camera) need_up; enter; camera "$@" ;;
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
