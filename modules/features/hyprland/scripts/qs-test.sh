T=${QS_TEST_DIR:-${XDG_RUNTIME_DIR:-/tmp}/qs-test}
repo=${QS_TEST_REPO:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}
host=${QS_TEST_HOST:-$(uname -n)}
src=$repo/modules/features/hyprland/quickshell

usage() {
  cat << EOF
usage: qs-test COMMAND

  up                 build the checkout's shell, start a headless sway and qs in $T
  down               stop both and remove the session and the test shell's state
  status             whether a session is up
  sync               copy the checkout's QML in, restart qs, print its warnings
  restart            restart qs, print its warnings
  lint               qmllint the checkout's shell, as nix flake check does

  ipc ARGS...        qs ipc call ARGS (panels open apps, notifications count, ...)
  type TEXT          type into the focused surface
  key [MOD+]...KEY   press a key (ctrl+n, shift+Tab, Escape)
  pointer DX DY      move the pointer by DX DY
  shot [NAME] [GEOM] screenshot ("x,y wxh" for a region), prints its path
  output MODE [SCALE] resize the output (2560x1440 1.5)
  x CMD...           run CMD inside the session (notify-send, swaymsg, ...)

  log                qs's whole log
  problems           its warnings and errors, less the expected ones
  actions            what the shell tried to run on the machine (power, hyprctl, ...)

env: QS_TEST_DIR (session dir), QS_TEST_HOST (host whose shell is built, $host),
     QS_TEST_REPO (checkout), QS_TEST_MODE (1920x1080), QS_TEST_SCALE (1)
EOF
}

die() {
  echo "qs-test: $*" >&2
  exit 1
}

running() { [ -s "$T/sway.pid" ] && kill -0 "$(cat "$T/sway.pid")" 2> /dev/null; }
need_up() { running || die "no session in $T; run qs-test up"; }

# By config path, since setsid may fork and leave no pid to remember.
testqs() {
  qs list --all 2> /dev/null | awk -v path="$T/shell/shell.qml" '/Process ID/ { pid = $3 } /Config path/ && $3 == path { print pid }'
}

enter() {
  WAYLAND_DISPLAY=$(cat "$T/display")
  SWAYSOCK=$(cat "$T/swaysock")
  DBUS_SESSION_BUS_ADDRESS=$(cat "$T/bus")
  XDG_CONFIG_HOME=$T/cfg
  PATH=$T/bin:$PATH
  export WAYLAND_DISPLAY SWAYSOCK DBUS_SESSION_BUS_ADDRESS XDG_CONFIG_HOME PATH
  unset HYPRLAND_INSTANCE_SIGNATURE
}

problems() {
  grep -E 'WARN|ERROR' "$T/qs.log" | grep -vE 'GlobalShortcut|UPower|[Hh]yprland|qt\.qpa\.wayland|portal' || true
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

build_shell() {
  # path:, since a git flake leaves untracked files out
  nix build --no-link --print-out-paths --impure --expr \
    "(builtins.getFlake \"path:$repo\").nixosConfigurations.$host.config.home-manager.users.$USER.programs.quickshell.configs.shell"
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
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl > /dev/null; then
    hyprctl binds -j > "$T/binds.json"
  else
    echo '[]' > "$T/binds.json"
  fi
  hyprmoncfg status --json > "$T/status.json" 2> /dev/null || echo '{"profiles":[]}' > "$T/status.json"
  : > "$T/actions.log"

  cat > "$T/bin/hyprctl" << EOF
#!/bin/sh
case "\$1" in binds) cat "$T/binds.json" ;; *) echo "hyprctl \$*" >> "$T/actions.log" ;; esac
EOF
  cat > "$T/bin/hyprmoncfg" << EOF
#!/bin/sh
case "\$1" in status) cat "$T/status.json" ;; *) echo "hyprmoncfg \$*" >> "$T/actions.log" ;; esac
EOF
  for entry in systemctl loginctl; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/actions.log"\n' "$entry" "$T" > "$T/bin/$entry"
  done
  cliphist=$(command -v cliphist || true)
  if [ -n "$cliphist" ]; then
    [ -f "$HOME/.cache/cliphist/db" ] && cp "$HOME/.cache/cliphist/db" "$T/clip.db"
    printf '#!/bin/sh\nexec %s -db-path "%s/clip.db" "$@"\n' "$cliphist" "$T" > "$T/bin/cliphist"
  fi
  chmod +x "$T/bin/"*

  for entry in "$config"/*; do
    [ "$(basename "$entry")" = hyprmoncfg ] || ln -sfn "$entry" "$T/cfg/"
  done
  [ -e "$config/hyprmoncfg/profiles" ] && ln -sfn "$config/hyprmoncfg/profiles" "$T/cfg/hyprmoncfg/profiles"
  return 0
}

up() {
  if running; then
    echo "up in $T"
    return
  fi
  local shell
  shell=$(build_shell)
  mkdir -p "$T/shots"
  rm -rf "$T/shell" "$T/display" "$T/swaysock"
  cp -rL "$shell" "$T/shell"
  chmod -R u+w "$T/shell"
  fakes

  cat > "$T/sway.cfg" << EOF
output HEADLESS-1 mode ${QS_TEST_MODE:-1920x1080} scale ${QS_TEST_SCALE:-1}
output * bg $repo/modules/features/hyprland/assets/wallpaper.png fill
exec sh -c 'echo \$SWAYSOCK > "$T/swaysock"; echo \$WAYLAND_DISPLAY > "$T/display"'
EOF
  cat > "$T/run.sh" << EOF
#!/bin/sh
echo \$DBUS_SESSION_BUS_ADDRESS > "$T/bus"
echo \$\$ > "$T/sway.pid"
unset HYPRLAND_INSTANCE_SIGNATURE
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 exec sway -c "$T/sway.cfg"
EOF
  chmod +x "$T/run.sh"
  setsid dbus-run-session -- "$T/run.sh" > "$T/sway.log" 2>&1 < /dev/null &
  for _ in $(seq 100); do
    [ -s "$T/display" ] && break
    sleep 0.1
  done
  [ -s "$T/display" ] || die "sway did not start, see $T/sway.log"
  start_qs
  echo "up in $T"
}

down() {
  local bus="" pid id
  stop_qs
  [ -s "$T/bus" ] && bus=$(cat "$T/bus")
  if running; then kill "$(cat "$T/sway.pid")"; fi
  # Portals the private bus activated outlive it, reparented to pid 1.
  if [ -n "$bus" ]; then
    for pid in /proc/[0-9]*; do
      pid=${pid#/proc/}
      tr '\0' '\n' 2> /dev/null < "/proc/$pid/environ" | grep -qxF "DBUS_SESSION_BUS_ADDRESS=$bus" && kill "$pid" 2> /dev/null
    done
  fi
  # Quickshell keys its dirs by config path, so these are the test shell's own.
  id=$(grep -o 'Shell ID: "[0-9a-f]*' "$T/qs.log" 2> /dev/null | head -1 | cut -d'"' -f2 || true)
  if [ -n "$id" ]; then
    rm -rf "$HOME/.local/state/quickshell/by-shell/$id" "$HOME/.cache/quickshell/by-shell/$id"
  fi
  rm -rf "$T"
  echo down
}

shot() {
  local name=${1:-shot} file
  file=$T/shots/$(printf '%03d' "$(find "$T/shots" -name '*.png' | wc -l)")-$name.png
  enter
  if [ -n "${2:-}" ]; then grim -g "$2" "$file"; else grim "$file"; fi
  echo "$file"
}

# wtype's first key reaches nobody, so a shift goes first.
key() {
  local parts mods=() mod
  IFS=+ read -ra parts <<< "$1"
  for mod in "${parts[@]:0:${#parts[@]}-1}"; do mods+=("$mod"); done
  local args=(-s 150 -k Shift_L)
  for mod in "${mods[@]}"; do args+=(-M "$mod"); done
  args+=(-k "${parts[-1]}")
  for mod in "${mods[@]}"; do args+=(-m "$mod"); done
  enter
  wtype "${args[@]}"
}

cmd=${1:-help}
shift || true
case $cmd in
  up) up ;;
  down) down ;;
  status) if running; then echo "up in $T, qs $(testqs)"; else echo down; fi ;;
  sync) need_up; stop_qs; sync_source; start_qs ;;
  restart) need_up; stop_qs; start_qs ;;
  lint) qs-lint "$(build_shell)" ;;
  ipc) need_up; enter; timeout 5 qs ipc -p "$T/shell" call "$@" ;;
  type) need_up; enter; wtype -s 150 -k Shift_L "$*" ;;
  key) need_up; for k in "$@"; do key "$k"; done ;;
  pointer) need_up; enter; wlrctl pointer move "$@" ;;
  shot) need_up; shot "$@" ;;
  output) need_up; enter; swaymsg output HEADLESS-1 mode "$1" scale "${2:-1}" ;;
  x) need_up; enter; exec "$@" ;;
  log) cat "$T/qs.log" ;;
  problems) problems ;;
  actions) cat "$T/actions.log" ;;
  help | -h | --help) usage ;;
  *) usage >&2; exit 1 ;;
esac
