T=${QS_TEST_DIR:-${XDG_RUNTIME_DIR:-/tmp}/qs-test}
repo=${QS_TEST_REPO:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}
host=${QS_TEST_HOST:-$(uname -n)}
src=$repo/modules/features/hyprland/quickshell
tests=$repo/modules/features/hyprland/tests
self=$(readlink -f "$0")
# What outlives a session: each job's last time, so the longest start first, and the last run's failures.
hist=${XDG_STATE_HOME:-$HOME/.local/state}/qs-test

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
  gallery               open tests/Gallery.qml, every common/ piece in every state
  state [JQ]            what the shell sees (tests/Probe.qml) with Hyprland's layers and monitors, through JQ
  wait JQ [SECONDS]     until JQ holds on the state (5 s), or fail and print it
  stays JQ [SECONDS]    fail if JQ stops holding within SECONDS (1)
  reset                 QS_TEST_MONITORS again, ids from 0, no windows, and a fresh qs without saved state
  case NAME             a test's next case: check the last one left no problems, print it and reset
  expect [--may] REGEX  this case must (or may) log a warning matching REGEX
  check                 whether the case so far left problems
  run [-j N] [--fail-fast] [--failed|--failed-first] [--changed] [FILE[:CASE-REGEX]...]
                        the checkout's QML into N sessions side by side (by cores and memory; 1: this one),
                        and every case of tests/scenarios/*.sh, or those given, longest first; qst on PATH;
                        --failed takes only the last run's failures; the output is kept in $hist/last-run.log
  red [REV] FILE[:CASE-REGEX]...  those cases on REV's QML (HEAD) with the checkout's tests, in this session: each must fail
  trace                 the qst calls of the case so far, by seconds into it
  jobs [FILE[:REGEX]...]  the jobs a run would take, in its order
  timings               the last run's slowest cases and where the time went
  key COMBO...          press keys in turn (ctrl+n, super+d, shift+Tab, Escape)
  hold COMBO MS         hold a key down for MS, so the client repeats it
  type TEXT             type TEXT into the focused surface
  pointer X Y           put the pointer at X Y in layout coordinates (hover)
  move DX DY            move the pointer by DX DY
  click [BUTTON] [X Y | [WINDOW:]NAME [DX DY]]   click left (or right, middle), at X Y, or DX DY off the area named NAME
  area [WINDOW:]NAME    where the area named NAME (pill:wifi, ControlsPanel:row:wg0) is, as "x y"; a miss lists the names there
  press|release BUTTON  hold or let go of a button
  drag X Y DX DY [MS]   press left at X Y, glide DX DY over MS (300) ms, release
  wheel STEPS [horizontal]  scroll STEPS notches, positive down or right
  spin STEPS            STEPS one-notch events at once, a wheel spun hard
  layers                the layer surfaces up, by namespace and monitor
  shot [NAME] [WHERE]   screenshot of everything, a monitor, or "x,y wxh"; prints its path
  monitor add NAME [MODE] [SCALE] [POSITION]   plug a monitor in (1920x1080, 1, auto-right)
  monitor remove NAME   unplug it
  monitor disable NAME  turn it off as a hyprmoncfg profile does; enable turns it back on
  monitors              the monitors, disabled ones too
  focus NAME            focus a monitor
  output MODE [SCALE]   change the first monitor's mode (2560x1440 1.5)
  pipewire start|stop|restart   the session's own sound server (tests/pipewire.conf)
  network SUB ...       the session's NetworkManager (tests/networkmanager.py): start|stop|restart, wifi add SSID [STRENGTH] [SECURITY] [PASSWORD],
                        wifi remove|strength|clear|many COUNT [PREFIX]|json JSON, device add|remove NAME [wifi|ethernet], cable NAME on|off,
                        profile wifi|ethernet|wireguard|vpn NAME [SSID PSK], vpn NAME ok|fail|secrets, up NAME,
                        connectivity none|portal|limited|full, switch on|off, delay MS, dump
  player add NAME [IDENTITY] [STATUS] [ART]   an MPRIS player (tests/mpris.py), ART an image file for its cover; status NAME Playing|Paused|Stopped, remove NAME, clear
  battery PERCENT [STATE [SECONDS]]   the session's UPower battery (charging, discharging, full, pending), or remove
  bluetooth SUB ...     the session's BlueZ (tests/bluez.py): start|stop, adapter add|remove, remove ADDRESS,
                        add ADDRESS NAME [ICON] [ok|pin|fail|crowded] [paired] [connected] [BATTERY]
  backlight NAME VALUE [MAX]    set a fake backlight (max 100) and announce it as udev does; NAME remove unplugs it
  camera open|close NAME [DEV]  a process named NAME holding a fake camera (video0) open; add|remove DEV
                        add DEV locked plugs one in root's alone, as devtmpfs makes it; unlock DEV is udev handing it on
  spawn CMD...          start CMD in the session, detached (output in spawn.log)
  tray [log]            add a test tray item with submenus (tests/tray.qml), or show what it was told
  tray add NAME [COUNT] COUNT items under the app id NAME (tests/trays.qml); remove NAME, clear
  flood COUNT [OPTIONS] COUNT notifications as fast as the bus takes them (qs-flood --help)
  x CMD...              run CMD in the session (notify-send, hyprctl, ...)

  log                   qs's whole log
  hyprlog               Hyprland's log
  problems              qs's warnings and errors, less tests/known-warnings and expected ones
  census                what the probe finds wrong on screen now
  areas [REGEX]         mouse areas on screen by label: x y label enabled clicks hand
  cursor X Y [SHAPE]    the cursor there and what set it; fails if not SHAPE (hand, arrow, closed)
  cursors [WINDOW]      fail where an area that asks for a hand shows none, in WINDOW (BarWindow, LauncherWindow, …) or all
  motion start|stop     record every visible item each frame; stop prints what moved, failing on a jump
  fail TOOL MODE        TOOL fails as MODE (exit, crash, missing, garbage, off) wherever the shell runs it
  actions               what the session tried to run on the machine (power, systemd-run, ...)

env: QS_TEST_DIR (session dir), QS_TEST_HOST (host whose config is built, $host),
     QS_TEST_NETWORK, QS_TEST_BLUETOOTH (none: no NetworkManager, no BlueZ), QS_TEST_SCALE (the shell's QT_SCALE_FACTOR, 1),
     QS_TEST_REPO (checkout), QS_TEST_MONITORS (NAME:MODE:SCALE ..., DP-1:1920x1080:1)
EOF
}

die() {
  echo "qs-test: $*" >&2
  exit 1
}

# Milliseconds in REPLY, without a fork; the locale may write a comma in it.
ms() {
  local t=${EPOCHREALTIME//[!0-9]/}
  REPLY=$((t / 1000))
}

# One line of $T/timings.tsv: file, case, what, milliseconds, and anything else.
timing() {
  [ -d "$T" ] || return 0
  local name=-
  [ -s "$T/case" ] && read -r name < "$T/case"
  printf '%s\t%s\t%s\t%s\t%s\n' "${QST_FILE:--}" "$name" "$1" "$2" "${3:-}" >> "$T/timings.tsv"
}

# Each call a case makes, by seconds into it, so a failure shows what led there.
trace() {
  local start line cmd=$1
  shift
  read -r start 2> /dev/null < "$T/case-start" || return 0
  ms
  printf -v line '%4d.%d s  qst %s %s' $(((REPLY - start) / 1000)) $(((REPLY - start) % 1000 / 100)) "$cmd" "${*@Q}"
  printf '%s\n' "${line:0:200}" >> "$T/trace.log"
}

# The keys a failed filter reads, and the panel: the whole state grows with every list and the history, so it goes to a file.
state_slice() {
  local keys slice
  printf '%s\n' "$snap_json" > "$T/failed-state.json"
  keys=$(grep -oE '\.[A-Za-z_][A-Za-z0-9_]*' <<< "${1:-}" | cut -c2- | jq -Rsc 'split("\n") | map(select(. != "")) + ["panel"]')
  slice=$(jq -c --argjson keys "$keys" 'with_entries(select(.key as $k | $keys | any(. == $k)))' <<< "$snap_json")
  [ ${#slice} -le 3000 ] || slice="${slice:0:3000} …"
  echo "$slice" >&2
  echo "qs-test: the whole state is in $T/failed-state.json" >&2
}

# A part of reset run beside others, timed on its own.
alongside() {
  local began
  ms
  began=$REPLY
  "$1"
  ms
  timing "reset~$1" $((REPLY - began))
}

phase_at=0
phase() {
  ms
  timing "reset:$1" $((REPLY - phase_at))
  phase_at=$REPLY
}

running() { [ -s "$T/hyprland.pid" ] && kill -0 "$(cat "$T/hyprland.pid")" 2> /dev/null; }
need_up() { running || die "no session in $T; run qs-test up"; }

enter() {
  # Builtins only: it runs on every call, every snapshot among them.
  read -r XDG_RUNTIME_DIR < "$T/runtime"
  read -r WAYLAND_DISPLAY < "$T/display"
  read -r HYPRLAND_INSTANCE_SIGNATURE < "$T/signature"
  read -r DBUS_SESSION_BUS_ADDRESS < "$T/bus"
  XDG_CONFIG_HOME=$T/cfg
  XDG_CURRENT_DESKTOP=Hyprland
  # Ahead of all else every time, as each qst puts its own tools first, or the real nmcli and brightnessctl win over the fakes.
  PATH=$T/bin:${PATH//"$T/bin:"/}
  DBUS_SYSTEM_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/system_bus_socket
  # Qt finds the time zone's files only through it on NixOS; the user's systemd session sets it, a shell may not.
  TZDIR=${TZDIR:-/etc/zoneinfo}
  read -r HC < "$T/build"
  HC=$HC/hyprland/bin/hyprctl
  export XDG_RUNTIME_DIR WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS DBUS_SYSTEM_BUS_ADDRESS TZDIR XDG_CONFIG_HOME XDG_CURRENT_DESKTOP PATH
  unset DISPLAY SWAYSOCK
}

shell_id() { printf '%s' "$T/shell/shell.qml" | md5sum | cut -d' ' -f1; }

# By config path, since setsid may fork and leave no pid to remember.
testqs() {
  (
    enter
    qs list --all 2> /dev/null | awk -v path="$T/shell/shell.qml" '/Process ID/ { pid = $3 } /Config path/ && $3 == path { print pid }'
  )
}

# The regexes no case fails on: tests/known-warnings, and what this case expects (`expect`).
allowed() {
  grep -v '^#' "$tests/known-warnings" | cut -f1
  [ -s "$T/expected" ] && cut -f2- "$T/expected"
  return 0
}

# qs's warnings from line $1 on that nothing allows, and whether it still runs.
problems() {
  local patterns
  patterns=$(allowed | paste -sd '|')
  # With no output at all, Qt moves windows to a placeholder screen for a moment, and each warns before it is gone or placed.
  tail -n +"${1:-1}" "$T/qs.log" | grep -aE 'WARN|ERROR|creating placeholder screen' |
    awk '/creating placeholder screen/ { held = 1; next } held && /Layershell screen does not correspond/ { next } { held = 0; print }' |
    grep -vE "${patterns:-^$}" || true
  if running && [ -s "$T/display" ] && ! alive; then echo "qs is not running: it crashed or failed to load"; fi
  [ -s "$T/ipc-missing" ] && cat "$T/ipc-missing"
  return 0
}

# A case fails on any warning it caused, and on a `qst expect` that never came.
case_check() {
  local found mark name pid peak
  [ -s "$T/case" ] || return 0
  name=$(cat "$T/case")
  if [ -s "$T/case-start" ]; then
    ms
    timing case $((REPLY - $(cat "$T/case-start")))
    rm -f "$T/case-start"
  fi
  mark=$(cat "$T/case-mark" 2> /dev/null || echo 1)
  found=$(problems "$mark")
  # Peak, as every case starts a qs of its own: a flood or a list built over and over shows here first.
  for pid in $(testqs); do
    peak=$(awk '/VmHWM/ { print int($2 / 1024) }' "/proc/$pid/status" 2> /dev/null || echo 0)
    [ "${peak:-0}" -le "${QS_TEST_PEAK:-1024}" ] || found+=$'\n'"qs peaked at $peak MiB, past the ${QS_TEST_PEAK:-1024} MiB a case may take"
  done
  if [ -s "$T/expected" ]; then
    # One that came stays allowed, but need not come again in the log a restart starts.
    while IFS=$'\t' read -r kind pattern; do
      if [ "$kind" = must ] && ! tail -n +"$mark" "$T/qs.log" | grep -qE "$pattern"; then
        found+=$'\n'"expected a warning matching $pattern, which never came"
      fi
      printf 'may\t%s\n' "$pattern"
    done < "$T/expected" > "$T/expected.new"
    mv "$T/expected.new" "$T/expected"
  fi
  found=$(sed '/^$/d' <<< "$found")
  [ -z "$found" ] && return 0
  echo "qs-test: \"$name\" left problems:" >&2
  echo "$found" >&2
  exit 1
}

# An IpcHandler in a singleton nothing has read yet does not exist, and qs ipc then answers "Target not found." with status 0.
ipc_targets() {
  local declared shown
  declared=$(grep -rhoP '^\s*target: "\K[^"]+' "$T/shell" --include='*.qml' | sort -u)
  shown=$(enter && timeout 5 qs ipc -p "$T/shell" show | awk '/^target / { print $2 }' | sort -u)
  comm -23 <(echo "$declared") <(echo "$shown") | sed 's/^/IPC target /; s/$/ is declared but not registered: nothing has read its singleton/' > "$T/ipc-missing"
}

start_qs() {
  local tailer
  # Emptied first, so the last qs's "Configuration Loaded" is never read as this one's.
  : > "$T/qs.log"
  (
    enter
    # Qt names the item behind every cursor change, which `cursor` reads back.
    QT_SCALE_FACTOR=${QS_TEST_SCALE:-1} QT_LOGGING_RULES=qt.quick.hover.cursor.debug=true setsid qs -p "$T/shell" > "$T/qs.log" 2>&1 < /dev/null &
    echo $! > "$T/qs.pid"
  )
  echo 1 > "$T/case-mark"
  rm -f "$T/countdowns.json"
  # As the line is written, rather than polling for it.
  exec 3< <(exec tail -n +1 -s 0.05 -F "$T/qs.log" 2> /dev/null)
  tailer=$!
  timeout 10 grep -m1 -qaE 'Configuration Loaded|Failed to load' <&3 || true
  kill "$tailer" 2> /dev/null || true
  exec 3<&-
  grep -q 'Configuration Loaded' "$T/qs.log" || { problems; die "the shell did not load, see qs-test log"; }
  [ -e "$T/ipc-checked" ] || { ipc_targets; : > "$T/ipc-checked"; }
  problems
}

# The whole process group setsid made it, as systemd takes the service's cgroup: the watchers it runs (camera-users,
# backlight-watch) wait on inotify with nobody reading them, and each would scan /proc for every case after.
stop_qs() {
  local pids="" pid left
  if [ -s "$T/qs.pid" ]; then
    read -r pid < "$T/qs.pid"
    kill -0 "$pid" 2> /dev/null && pids=$pid
    rm -f "$T/qs.pid"
  fi
  [ -n "$pids" ] || pids=$(testqs)
  [ -n "$pids" ] || return 0
  for pid in $pids; do kill -- "-$pid" 2> /dev/null || kill "$pid" 2> /dev/null || true; done
  for _ in $(seq 250); do
    left=0
    for pid in $pids; do kill -0 -- "-$pid" 2> /dev/null && left=1; done
    [ $left = 1 ] || return 0
    sleep 0.02
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
      hyprsunset = home.services.hyprsunset.package;
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
  rm -f "$T/ipc-checked"
  install_probe
}

# The test's own window into the shell, in its copy only.
install_probe() {
  mkdir -p "$T/shell/probe"
  cp "$tests"/Probe*.qml "$tests"/Gallery*.qml "$T/shell/probe/"
  sed -i -e 's/^import Quickshell$/&\nimport qs.probe/' -e '$ s/^}$/\n  Probe {}\n  Gallery {}\n}/' "$T/shell/shell.qml"
  grep -q 'Probe {}' "$T/shell/shell.qml" || die "could not add the probe to shell.qml"
  local file name
  while IFS= read -r file; do
    name=${file#"$T/shell/"}
    sed -i -E -e "s#^((\\s*)(component \\w+: )?(PanelWindow|PopupWindow|FloatingWindow|Overlay|Popover) \\{)\$#\\1\\n\\2  ProbeWindow {\\n\\2    file: \"${name%.qml}\"\\n\\2  }\\n#" -e '0,/^import /s/^import /import qs.probe\nimport /' "$file"
  done < <(grep -rlE '(PanelWindow|PopupWindow|FloatingWindow|^Overlay|^Popover) \{$' "$T/shell" --include='*.qml')
  # Register each Behavior on color so the census validates its target while a ColorAnimation is running.
  while IFS= read -r file; do
    sed -i -E -e 's#^(\s*)Behavior on color \{$#\1Behavior on color {\n\1  Component.onCompleted: ProbeWindows.trackColor(parent, this)\n\1  Component.onDestruction: ProbeWindows.untrackColor(parent, this)#' "$file"
    grep -q '^import qs\.probe$' "$file" || sed -i -E '0,/^import /s/^import /import qs.probe\nimport /' "$file"
  done < <(grep -rlE '^\s*Behavior on color \{$' "$T/shell" --include='*.qml')
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
case "\$1" in nixpkgs-run | xdg-open | freeze-region) exit ;; nixpkgs-index) exec "\$@" ;; esac
# Its own process group, which reset kills: a window still starting has no client to kill yet.
echo \$\$ >> "$T/launched"
exec setsid "\$@"
EOF
  # The package list, a handful of packages rather than the channel's 400 MB, written once per session.
  cat > "$T/bin/nixpkgs-index" << EOF
#!/bin/sh
echo "nixpkgs-index \$*" >> "$T/actions.log"
head -n 1 "\$1" 2> /dev/null | grep -q '^qs-test' && exit
mkdir -p "\$(dirname "\$1")"
printf '%s\t%s\t%s\t%s\t%s\n' qs-test qs-test '' '' '' \\
  firefox firefox 140.0 '' 'A web browser built from Firefox source tree' \\
  firefox-esr firefox 128.0 '' 'Extended support release of Firefox' \\
  firejail firejail 0.9.74 '' 'Namespace-based sandboxing tool for Linux' \\
  hello hello 2.12.2 '' 'Program that produces a familiar, friendly greeting' \\
  steam steam 1.0.0.85 unfree 'Digital distribution platform' > "\$1"
echo updated
EOF
  # MET Norway answers from here: twelve hours from this one, expiring in an hour, and unmodified to If-Modified-Since.
  cat > "$T/bin/curl" << EOF
#!/bin/sh
echo "curl \$*" >> "$T/actions.log"
case "\$*" in *api.met.no*) ;; *) exec "$(command -v curl)" "\$@" ;; esac
modified="Mon, 01 Jan 2024 00:00:00 GMT"
expires=\$(date -u -d '+1 hour' '+%a, %d %b %Y %H:%M:%S GMT')
case "\$*" in
  *"If-Modified-Since: \$modified"*) printf 'HTTP/2 304\r\nexpires: %s\r\n\r\n' "\$expires"; exit ;;
esac
printf 'HTTP/2 200\r\nexpires: %s\r\nlast-modified: %s\r\n\r\n' "\$expires" "\$modified"
"$(command -v jq)" -cn --argjson now "\$(date -u +%s)" '{ properties: { timeseries: [range(12) as \$h | { time: ((\$now / 3600 | floor) + \$h) * 3600 | todate, data: { instant: { details: { air_temperature: (5 + \$h) } }, next_1_hours: { summary: { symbol_code: (if \$h % 2 == 0 then "clearsky_day" else "rain" end) } } } }] } }'
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
  for entry in loginctl pw-play xdg-open nixpkgs-run freeze-region; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/actions.log"\n' "$entry" "$T" > "$T/bin/$entry"
  done
  # libnm will not register its secret agent with a NetworkManager not run by root, so the fake brings a profile up.
  cat > "$T/bin/nmcli" << EOF2
#!/bin/sh
real=$(command -v nmcli)
case " \$* " in
  *" connection up "* | *" con up "* | *" c up "*) ;;
  # what a connection does on the machine, the mock cannot reapply
  *" device modify "* | *" device reapply "*) echo "nmcli \$*" >> "$T/actions.log"; exit 0 ;;
  *) exec "\$real" "\$@" ;;
esac
echo "nmcli \$*" >> "$T/actions.log"
while [ \$# -gt 0 ] && [ "\$1" != up ]; do shift; done
shift
case "\$1" in id | uuid) shift ;; esac
name=\$1
shift
secrets=false
for arg in "\$@"; do [ "\$arg" = passwd-file ] && secrets=true; done
dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.DBus.Mock.Up "string:\$name" "boolean:\$secrets" > /dev/null || exit 10
# As nmcli waits: until the profile is up, or it has gone down again; Up made it activating, so gone from the list is down, however soon.
for _ in \$(seq 150); do
  state=\$("\$real" -t -f NAME,UUID,STATE connection show --active | awk -F: -v name="\$name" '\$1 == name || \$2 == name { print \$3 }')
  case "\$state" in
    activated) echo "Connection successfully activated"; exit 0 ;;
    "")
      why=\$(dbus-send --system --print-reply=literal --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.DBus.Mock.Dump | jq -r --arg name "\$name" '.profiles[] | select(.id == \$name or .uuid == \$name) | .behaviour')
      if [ "\$why" = secrets ]; then echo "Error: Connection activation failed: Secrets were required, but not provided." >&2; else echo "Error: Connection activation failed: (qs-test) the profile went down." >&2; fi
      exit 4
      ;;
  esac
  sleep 0.1
done
echo "Error: Timeout expired." >&2
exit 3
EOF2
  # The real one reaches this machine's backlight: this one sets the fake ones and announces it as udev does.
  cat > "$T/bin/brightnessctl" << EOF2
#!/bin/sh
echo "brightnessctl \$*" >> "$T/actions.log"
device=""
value=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    --device | -d) device=\$2; shift ;;
    --device=*) device=\${1#--device=} ;;
    set) value=\$2; shift ;;
  esac
  shift
done
dir="$T/backlight/\$device"
[ -d "\$dir" ] || { echo "Device '\$device' not found." >&2; exit 1; }
max=\$(cat "\$dir/max_brightness")
case "\$value" in *%) level=\$((\${value%\%} * max / 100)) ;; *) level=\$value ;; esac
echo "\$level" > "\$dir/brightness"
echo "\$level" > "\$dir/actual_brightness"
printf 'UDEV  [%s] change   /devices/qs-test/backlight/%s (backlight)\n' "\$(date +%s.%N)" "\$device" >> "$T/udev"
EOF2
  cliphist=$(command -v cliphist || true)
  if [ -n "$cliphist" ]; then
    [ -f "$HOME/.cache/cliphist/db" ] && cp "$HOME/.cache/cliphist/db" "$T/clip.db"
    printf '#!/bin/sh\nexec %s -db-path "%s/clip.db" "$@"\n' "$cliphist" "$T" > "$T/bin/cliphist"
  fi
  find "$T/bin" -maxdepth 1 -type f -exec chmod +x {} +

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
    for _ in $(seq 250); do
      # The socket is there as it is bound, before it listens; WirePlumber connecting then gives up for good.
      [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && timeout 1 pw-cli info 0 > /dev/null 2>&1 && break
      sleep 0.02
    done
    setsid wireplumber > "$T/wireplumber.log" 2>&1 < /dev/null &
    echo $! > "$T/wireplumber.pid"
  )
  (
    enter
    for _ in $(seq 500); do
      # wpctl can hang on a server still coming up.
      timeout 2 wpctl inspect @DEFAULT_AUDIO_SINK@ > /dev/null 2>&1 && timeout 2 wpctl inspect @DEFAULT_AUDIO_SOURCE@ > /dev/null 2>&1 && break
      sleep 0.02
    done
    timeout 5 wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.64
  ) || die "PipeWire did not start, see $T/pipewire.log and $T/wireplumber.log"
}

pw_stop() {
  local name pid
  for name in wireplumber pipewire; do
    [ -s "$T/$name.pid" ] || continue
    pid=$(cat "$T/$name.pid")
    kill "$pid" 2> /dev/null || true
    for _ in $(seq 250); do
      kill -0 "$pid" 2> /dev/null || break
      sleep 0.02
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

# The session's own system bus, so nothing in a test reaches this machine's NetworkManager, UPower or BlueZ.
sysbus_start() {
  cat > "$T/system-bus.conf" << EOF2
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>system</type>
  <listen>unix:path=$XDG_RUNTIME_DIR/system_bus_socket</listen>
  <auth>EXTERNAL</auth>
  <!-- The system bus allows 128, which Quickshell runs into past ~128 access points; tests of the lists need more. -->
  <limit name="max_replies_per_connection">50000</limit>
  <policy context="default">
    <allow user="*"/>
    <allow own="*"/>
    <allow send_type="method_call"/>
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
  </policy>
</busconfig>
EOF2
  dbus-daemon --config-file="$T/system-bus.conf" --fork --print-pid > "$T/system-bus.pid" || die "the session's system bus did not start"
}

owned() { dbus-send --system --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.NameHasOwner "string:$1" 2> /dev/null | grep -q 'boolean true'; }

# A service on the session's system bus from a dbusmock template, its log in $T/NAME.log.
mock_start() {
  local name=$1 bus=$2 template=$3 params=${4:-"{}"}
  mock_stop "$name"
  setsid qs-dbusmock --system --template "$template" -p "$params" > "$T/$name.log" 2>&1 < /dev/null &
  echo $! > "$T/$name.pid"
  for _ in $(seq 250); do
    owned "$bus" && return
    sleep 0.02
  done
  die "the fake $name did not start, see $T/$name.log"
}

mock_stop() {
  local pid
  [ -s "$T/$1.pid" ] || return 0
  pid=$(cat "$T/$1.pid")
  kill "$pid" 2> /dev/null || true
  for _ in $(seq 125); do
    kill -0 "$pid" 2> /dev/null || break
    sleep 0.02
  done
  rm -f "$T/$1.pid"
}

nm() {
  local method=$1
  shift
  dbus-send --system --print-reply=literal --dest=org.freedesktop.NetworkManager /org/freedesktop/NetworkManager "org.freedesktop.DBus.Mock.$method" "$@"
}

# What a fresh case starts with, unless QS_TEST_NETWORK says none: the desktop's wired link and wg0
# up, and a Wi-Fi card in range of a saved network, a WPA3 one and an open one.
network_default() {
  jq -cn '{
    devices: [{ iface: "enp8s0", type: "ethernet", carrier: true, speed: 1000 }, { iface: "wlp5s0", type: "wifi", carrier: true, speed: 0 }],
    air: [
      { ssid: "Pixel_7128", bssid: "02:00:00:00:00:01", strength: 82, security: "wpa2", password: "hunter22", iface: "" },
      { ssid: "Hvit_Monster", bssid: "02:00:00:00:00:02", strength: 64, security: "wpa3", password: "monster", iface: "" },
      { ssid: "Kaffebrenneriet Gjest", bssid: "02:00:00:00:00:03", strength: 30, security: "open", password: "", iface: "" }
    ],
    profiles: [
      { uuid: "00000000-0000-4000-8000-000000000001", id: "enp8s0", type: "ethernet", ssid: "", psk: "", security: "open", behaviour: "ok", iface: "enp8s0", timestamp: 1 },
      { uuid: "00000000-0000-4000-8000-000000000002", id: "Pixel_7128", type: "wifi", ssid: "Pixel_7128", psk: "hunter22", security: "wpa2", behaviour: "ok", iface: "", timestamp: 1 },
      { uuid: "00000000-0000-4000-8000-000000000003", id: "wg0", type: "wireguard", ssid: "", psk: "", security: "open", behaviour: "ok", iface: "", timestamp: 1 }
    ],
    active: ["00000000-0000-4000-8000-000000000001", "00000000-0000-4000-8000-000000000003"],
    delay: 400
  }'
}

network_start() {
  mock_start network org.freedesktop.NetworkManager "$tests/networkmanager.py" "$(jq -cn --arg state "${1:-$(network_default)}" '{ state: $state }')"
}

# Fresh fakes for a case: NetworkManager as network_default, a battery at 76 % so the bar shows all it can,
# BlueZ with an adapter and nothing paired, and logind offering a firmware restart; QS_TEST_NETWORK or QS_TEST_BLUETOOTH set to none leaves that one out.
services_reset() {
  local fakes=() fake
  {
    mock_stop network
    [ "${QS_TEST_NETWORK:-default}" = none ] || network_start
  } &
  fakes+=($!)
  {
    mock_start power org.freedesktop.UPower "$tests/upower.py"
    battery 76 discharging 9600
  } &
  fakes+=($!)
  owned org.freedesktop.login1 || mock_start logind org.freedesktop.login1 "$tests/logind.py" &
  fakes+=($!)
  {
    mock_stop bluetooth
    if [ "${QS_TEST_BLUETOOTH:-default}" != none ]; then
      mock_start bluetooth org.bluez "$tests/bluez.py"
      bluez AddAdapter string:hci0 string:qs-test > /dev/null
    fi
  } &
  fakes+=($!)
  for fake in "${fakes[@]}"; do wait "$fake" || die "a fake service did not come back"; done
}

bluez() {
  local method=$1
  shift
  dbus-send --system --print-reply=literal --dest=org.bluez / "org.bluez.Mock.$method" "$@"
}

# PERCENT [STATE [SECONDS]]: charging, discharging, full or pending (plugged in, held at a threshold); or remove.
battery() {
  if [ "${1:-}" = remove ]; then set -- -1 discharging 0; fi
  dbus-send --system --print-reply=literal --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.DBus.Mock.SetBattery "double:${1:-76}" "string:${2:-discharging}" "int64:${3:-0}" > /dev/null
}

bluetooth() {
  local sub=${1:-}
  shift || true
  case $sub in
    start) mock_start bluetooth org.bluez "$tests/bluez.py"; bluez AddAdapter string:hci0 string:qs-test > /dev/null ;;
    stop) mock_stop bluetooth ;;
    adapter)
      case ${1:-} in
        add) bluez AddAdapter "string:${2:-hci0}" string:qs-test > /dev/null ;;
        remove) bluez RemoveAdapterWithDevices "string:${2:-hci0}" > /dev/null ;;
        *) die "bluetooth adapter add|remove [NAME]" ;;
      esac
      ;;
    # ADDRESS NAME [ICON] [ok|pin|fail|crowded] [paired] [connected] [BATTERY]
    add)
      [ $# -ge 2 ] || die "bluetooth add ADDRESS NAME [ICON] [ok|pin|fail|crowded] [paired] [connected] [BATTERY]"
      bluez AddFullDevice string:hci0 "string:$1" "string:$2" "string:${3:-audio-headset}" "string:${4:-ok}" "boolean:$([ "${5:-}" = paired ] && echo true || echo false)" "boolean:$([ "${6:-}" = connected ] && echo true || echo false)" "int32:${7:--1}" > /dev/null
      ;;
    remove) bluez RemoveFullDevice string:hci0 "string:$1" > /dev/null ;;
    *) die "bluetooth start|stop|adapter add|remove|add ADDRESS NAME ...|remove ADDRESS" ;;
  esac
}

network() {
  local sub=${1:-}
  shift || true
  case $sub in
    start) network_start "$(cat "$T/network.state" 2> /dev/null || network_default)" ;;
    # NetworkManager going away: the expected warnings are Quickshell's own as it loses the service.
    stop)
      nm Dump | sed 's/^ *//' > "$T/network.state"
      mock_stop network
      ;;
    restart)
      nm Dump | sed 's/^ *//' > "$T/network.state"
      network_start "$(cat "$T/network.state")"
      ;;
    wifi)
      case ${1:-} in
        add) [ $# -ge 2 ] || die "network wifi add SSID [STRENGTH] [SECURITY] [PASSWORD]"; nm AddNetwork "string:$2" "byte:${3:-60}" "string:${4:-wpa2}" "string:${5:-password}" "string:" > /dev/null ;;
        remove) nm RemoveNetwork "string:$2" > /dev/null ;;
        strength) nm SetStrength "string:$2" "byte:$3" > /dev/null ;;
        clear) nm ClearNetworks > /dev/null ;;
        # COUNT networks named PREFIX1 … in one call, or a JSON list of [ssid, strength, security, password]
        many) nm AddNetworksJson "string:$(jq -cn --argjson n "$2" --arg prefix "${3:-Network }" '[range($n) | ["\($prefix)\(. + 1)", ((. * 37) % 100), (if . % 9 == 0 then "open" else "wpa2" end), "password"]]')" > /dev/null ;;
        json) nm AddNetworksJson "string:$2" > /dev/null ;;
        *) die "network wifi add|remove|strength|clear|many|json" ;;
      esac
      ;;
    device)
      case ${1:-} in
        add) nm AddDevice "string:$2" "string:${3:-wifi}" boolean:true uint32:1000 > /dev/null ;;
        remove) nm RemoveDevice "string:$2" > /dev/null ;;
        *) die "network device add NAME wifi|ethernet, or remove NAME" ;;
      esac
      ;;
    cable) nm SetCarrier "string:$1" "boolean:$([ "${2:-on}" = on ] && echo true || echo false)" > /dev/null ;;
    profile) [ $# -ge 2 ] || die "network profile wifi|ethernet|wireguard|vpn NAME [SSID PSK]"; nm AddProfile "string:$1" "string:$2" "string:${3:-}" "string:${4:-}" > /dev/null ;;
    vpn) nm SetBehaviour "string:$1" "string:${2:-ok}" > /dev/null ;;
    up) nm Up "string:$1" boolean:false > /dev/null ;;
    connectivity)
      local value
      case ${1:-} in none) value=1 ;; portal) value=2 ;; limited) value=3 ;; full) value=4 ;; *) die "network connectivity none|portal|limited|full" ;; esac
      nm SetConnectivity "uint32:$value" > /dev/null
      ;;
    switch) nm SetHardwareSwitch "boolean:$([ "${1:-on}" = on ] && echo true || echo false)" > /dev/null ;;
    delay) nm SetDelay "uint32:$1" > /dev/null ;;
    dump) nm Dump | sed 's/^ *//' | jq . ;;
    *) die "network start|stop|restart|wifi|device|cable|profile|vpn|up|connectivity|switch|delay|dump" ;;
  esac
}

# MPRIS players on the session bus (tests/mpris.py), each a mock of its own: add NAME [IDENTITY] [Playing|Paused|Stopped].
player() {
  local sub=${1:-} name=${2:-}
  mkdir -p "$T/players"
  case $sub in
    add)
      [ -n "$name" ] || die "player add NAME [IDENTITY] [STATUS] [ART]"
      QS_MPRIS_NAME=$name setsid qs-dbusmock --session --template "$tests/mpris.py" -p "$(jq -cn --arg identity "${3:-$name}" --arg status "${4:-Playing}" --arg art "${5:+file://$(realpath "$5")}" '{ identity: $identity, status: $status, art: $art }')" > "$T/players/$name.log" 2>&1 < /dev/null &
      echo $! > "$T/players/$name.pid"
      for _ in $(seq 250); do
        dbus-send --session --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.NameHasOwner "string:org.mpris.MediaPlayer2.$name" 2> /dev/null | grep -q 'boolean true' && return
        sleep 0.02
      done
      die "the fake player $name did not start, see $T/players/$name.log"
      ;;
    status) dbus-send --session --print-reply --dest="org.mpris.MediaPlayer2.$name" /org/mpris/MediaPlayer2 org.freedesktop.DBus.Mock.SetStatus "string:$3" > /dev/null ;;
    remove)
      [ -s "$T/players/$name.pid" ] && kill "$(cat "$T/players/$name.pid")" 2> /dev/null
      rm -f "$T/players/$name.pid"
      ;;
    clear) players_reset ;;
    *) die "player add NAME [IDENTITY] [STATUS] [ART], status NAME STATUS, remove NAME, clear" ;;
  esac
}

players_reset() {
  local pid
  for pid in "$T"/players/*.pid; do
    [ -s "$pid" ] && kill "$(cat "$pid")" 2> /dev/null
    rm -f "$pid"
  done
  return 0
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
      snapshot "$filter"
      [ "$snap_held" = true ] && return
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
    add)
      if [ "${3:-}" = locked ]; then
        # Made aside and moved in, so it is never seen readable.
        : > "$T/dev/.$name"
        chmod 000 "$T/dev/.$name"
        mv "$T/dev/.$name" "$T/dev/$name"
      else
        : > "$T/dev/$name"
      fi
      ;;
    unlock) chmod 600 "$T/dev/$name" ;;
    remove) rm -f "$T/dev/$name" ;;
    *) die "camera open|close NAME [DEVICE], add DEVICE [locked], unlock DEVICE or remove DEVICE" ;;
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
  build=${QS_TEST_BUILD:-$(build)}
  mkdir -p "$T/shots" "$T/labwc"
  rm -rf "$T/shell" "$T/cfg" "$T/display" "$T/signature"
  echo "$build" > "$T/build"
  cp -rL "$build/shell" "$T/shell"
  chmod -R u+w "$T/shell"
  rm -f "$T/ipc-checked"
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
export XDG_RUNTIME_DIR="$runtime" XDG_CONFIG_HOME="$T/cfg" PATH="$T/bin:\$PATH" DBUS_SYSTEM_BUS_ADDRESS="unix:path=$runtime/system_bus_socket"
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
  sysbus_start
  services_reset
  pw_start
  XKB_DEFAULT_LAYOUT=$("$HC" getoption input:kb_layout -j | jq -r .str) \
    XKB_DEFAULT_VARIANT=$("$HC" getoption input:kb_variant -j | jq -r .str) \
    setsid qs-input serve "$XDG_RUNTIME_DIR/input" > "$T/input.log" 2>&1 < /dev/null &
  setsid "$build/hyprpaper/bin/hyprpaper" > "$T/hyprpaper.log" 2>&1 < /dev/null &
  setsid "$build/hyprsunset/bin/hyprsunset" --identity > "$T/hyprsunset.log" 2>&1 < /dev/null &
  for _ in $(seq 50); do
    [ -S "$XDG_RUNTIME_DIR/input" ] && break
    sleep 0.1
  done
  [ -S "$XDG_RUNTIME_DIR/input" ] || die "qs-input did not start, see $T/input.log"
  start_qs
  echo "up in $T"
}

down() {
  local bus="" runtime="" pid id worker
  for worker in "$T"/w[0-9]*/; do
    [ -d "$worker" ] && QS_TEST_DIR=${worker%/} "$self" down > /dev/null &
  done
  wait
  [ -s "$T/runtime" ] && runtime=$(cat "$T/runtime")
  [ -s "$T/bus" ] && bus=$(cat "$T/bus")
  [ -s "$T/runtime" ] && [ -s "$T/display" ] && stop_qs
  if running; then kill "$(cat "$T/hyprland.pid")"; fi
  # Whatever the session started outlives it, portals reparented to pid 1 among them.
  for pid in /proc/[0-9]*; do
    pid=${pid#/proc/}
    [ "$pid" = $$ ] && continue
    # No pipe: grep -q leaving early would kill tr, and pipefail would read the match as none.
    grep -qzxF -e "DBUS_SESSION_BUS_ADDRESS=${bus:-none}" -e "XDG_RUNTIME_DIR=${runtime:-none}" "/proc/$pid/environ" 2> /dev/null &&
      kill "$pid" 2> /dev/null
  done
  # Quickshell keys its dirs by config path, so these are the test shell's own.
  id=$(shell_id)
  rm -rf "$HOME/.local/state/quickshell/by-shell/$id" "$HOME/.cache/quickshell/by-shell/$id"
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
# Into snap_json; with FILTER, whether it holds as jq -e reads it into snap_held, and the census problems and broken invariants into snap_violations.
# One jq for all of it, since a snapshot is taken every poll.
snapshot() {
  local probe out popups began started answered
  ms
  began=$REPLY
  enter
  ms
  started=$REPLY
  probe=$(timeout 5 qs ipc -p "$T/shell" call probe state) || {
    alive || die "qs is not running: it crashed or failed to load, see qs-test log"
    die "the probe did not answer, see qs-test log"
  }
  ms
  answered=$((REPLY - started))
  [ -s "$T/countdowns.json" ] || echo '[]' > "$T/countdowns.json"
  [ -n "${invariants:-}" ] || invariants=$(< "$tests/invariants.jq")
  out=$(jq -rc --argjson answered "$answered" --slurpfile before "$T/countdowns.json" --slurpfile hyprland <("$HC" --batch 'j/layers; j/monitors all') "
    . + {
      layers: [\$hyprland[0] | to_entries[] | .key as \$m | .value.levels[][] | \"\\(\$m) \\(.namespace)\"],
      hypr: (\$hyprland[1] | map({ name, id, disabled, x, y, width, height, scale, focused })),
      answered: \$answered
    }
    | ($invariants)
    | ., .popups, (try ([${1:-true}] | length > 0 and (last | . != null and . != false)) catch false), (.problems + .invariants)[]" <<< "$probe")
  { IFS= read -r snap_json && IFS= read -r popups && IFS= read -r snap_held && mapfile -t snap_violations; } <<< "$out"
  echo "$popups" > "$T/countdowns.json"
  ms
  timing snapshot $((REPLY - began)) "$answered"
}

state() {
  snapshot
  jq -c "${1:-.}" <<< "$snap_json"
}

declare -A since=()

# A census problem or broken invariant that lasts 500 ms fails, as transitions pass through some for a frame or two; a countdown going back fails at once.
violations() {
  local now v
  local -A seen=()
  ms
  now=$REPLY
  # A violation worded anew each time never lasts by its words, so the time spent waiting for one to clear is capped.
  [ -n "${pending_since:-}" ] || pending_since=$now
  for v in "${snap_violations[@]}"; do
    [ -n "$v" ] || continue
    [ "${v:0:1}" = "!" ] && violated "${v:1}" "$snap_json"
    seen[$v]=${since[$v]:-$now}
    [ $((now - seen[$v])) -ge 500 ] && violated "$v" "$snap_json"
  done
  since=()
  for v in "${!seen[@]}"; do since[$v]=${seen[$v]}; done
  if [ ${#since[@]} -eq 0 ]; then
    pending_since=""
    return 0
  fi
  [ $((now - pending_since)) -lt 1500 ] || violated "$(printf '%s; ' "${!since[@]}")" "$snap_json"
  return 1
}

violated() {
  echo "qs-test: $1" >&2
  state_slice "${waiting_on:-} .problems .invariants"
  exit 1
}

# Until FILTER holds, as jq -e reads it, or fails after SECONDS.
wait_for() {
  local filter=$1 deadline held=0 clear began snaps=0
  waiting_on=$filter
  ms
  began=$REPLY
  deadline=$((began + ${2:-5} * 1000))
  while :; do
    snapshot "$filter"
    snaps=$((snaps + 1))
    clear=1
    violations || clear=0
    [ $held = 1 ] || [ "$snap_held" != true ] || held=1
    if [ $held = 1 ] && [ $clear = 1 ]; then
      ms
      timing "${wait_kind:-wait}" $((REPLY - began)) $snaps
      return
    fi
    ms
    if [ $held = 0 ] && [ "$REPLY" -ge "$deadline" ]; then
      echo "qs-test: timed out after ${2:-5} s waiting for: $filter" >&2
      state_slice "$filter"
      exit 1
    fi
    sleep 0.1
  done
}

# FILTER holds throughout SECONDS (1): what should stay as it is.
stays() {
  local filter=$1 deadline clear=1 began snaps=0
  waiting_on=$filter
  ms
  began=$REPLY
  deadline=$((began + $(awk -v s="${2:-1}" 'BEGIN { print int(s * 1000) }')))
  while ms && [ "$REPLY" -lt "$deadline" ] || [ $clear = 0 ]; do
    snapshot "$filter"
    snaps=$((snaps + 1))
    clear=1
    violations || clear=0
    if [ "$snap_held" != true ]; then
      echo "qs-test: no longer holds: $filter" >&2
      state_slice "$filter"
      exit 1
    fi
    sleep 0.1
  done
  ms
  timing stays $((REPLY - began)) "$snaps ${2:-1}"
}

# Every tray item a test started.
trays_reset() {
  local pid
  for pid in "$T/tray.pid" "$T"/trays/*.pid; do
    [ -s "$pid" ] && kill "$(cat "$pid")" 2> /dev/null || true
  done
  rm -rf "$T/tray.pid" "$T/trays"
}

# A fresh start for a test: QS_TEST_MONITORS again, the focus on the first, and a new qs with no state.
reset() {
  local pid
  ms
  phase_at=$REPLY
  enter
  trays_reset
  players_reset
  for pid in $("$HC" clients -j | jq -r '.[].pid'); do kill "$pid" 2> /dev/null || true; done
  if [ -s "$T/launched" ]; then
    while read -r pid; do kill -- "-$pid" 2> /dev/null || kill "$pid" 2> /dev/null || true; done < "$T/launched"
    rm -f "$T/launched"
  fi
  phase clients
  stop_qs
  phase stop_qs
  # Side by side, as none reaches the others; with the shell gone, none of it reaches a state file either.
  local parts=() part
  alongside pw_reset > "$T/reset.pw_reset.log" 2>&1 &
  parts+=($!)
  alongside services_reset > "$T/reset.services_reset.log" 2>&1 &
  parts+=($!)
  alongside camera_reset
  rm -rf "$T/units" "$T/backlight"
  mkdir -p "$T/backlight"
  alongside monitors_reset
  "$HC" dispatch "hl.dsp.focus({ monitor = \"$("$HC" monitors -j | jq -r 'min_by(.id).name')\" })" > /dev/null
  for part in "${parts[@]}"; do
    wait "$part" || { cat "$T"/reset.*.log >&2; die "the reset failed"; }
  done
  phase pipewire+services+monitors
  rm -rf "$HOME/.local/state/quickshell/by-shell/$(shell_id)"
  # The forecast is a cache the shell keeps across restarts; each case fetches its own.
  rm -f "$HOME/.cache/quickshell/by-shell/$(shell_id)/weather.json"
  : > "$T/actions.log"
  restore_tools
  start_qs > /dev/null
  problems
  phase start_qs
  wait_kind=reset:bar wait_for "(.screens | length) == ($("$HC" monitors -j | jq length)) and (.layers | map(select(endswith(\" quickshell:bar\"))) | length) == (.screens | length)" 10
}


# A scenario file as jobs, a line each: the file, the last line before its first case, a job's first and last line, whether it runs alone, its cases' names.
# A job is a top-level `qst case` up to the next, or a top-level loop that runs cases, and runs after the file's lines before its first case.
split_cases() {
  awk '
    { line[NR] = $0 }
    function starts(l) { return l ~ /^([A-Za-z_][A-Za-z0-9_]*=[^ ]* )*qst case / }
    END {
      n = 0
      for (i = 1; i <= NR; i++) {
        l = line[i]
        if (l == "" || l ~ /^[ \t#]/) continue
        if (starts(l)) { start[++n] = i; continue }
        # A compound over several lines: its body indented, its end back at the left edge.
        if (l ~ /^(for|while|until|if|case|select)[ (]|^[A-Za-z_][A-Za-z0-9_]*\(\) *\{$|^\{$/ && line[i + 1] ~ /^[ \t]/) {
          inner = 0
          for (j = i + 1; j <= NR && line[j] !~ /^(done|fi|esac|\})/; j++) if (line[j] ~ /qst case /) inner = 1
          if (inner && l !~ /\(\) *\{$/) start[++n] = i
          i = j
        }
      }
      for (k = 1; k <= n; k++) {
        last = k < n ? start[k + 1] - 1 : NR
        names = ""
        alone = 0
        for (i = start[k]; i <= last; i++)
          if (match(line[i], /qst case "[^"]*"/)) names = names (names == "" ? "" : " | ") substr(line[i], RSTART + 10, RLENGTH - 11)
        for (i = start[k]; i <= last; i++) if (line[i] ~ /# alone: /) alone = 1
        printf "%s\t%d\t%d\t%d\t%d\t%s\n", FILENAME, start[1] - 1, start[k], last, alone, names
      }
    }' "$1"
}

# FILE or FILE:CASE-REGEX, FILE a scenario's name (chaos), file name or path, as jobs.
select_jobs() {
  local arg file pattern
  for arg in "$@"; do
    file=${arg%%:*}
    pattern=""
    [ "$arg" = "$file" ] || pattern=${arg#*:}
    [ -f "$file" ] || file=$tests/scenarios/${file%.sh}.sh
    [ -f "$file" ] || die "no scenario $arg"
    # Jobs are cut from a copy by line, so an edit made while they run reaches none of them.
    mkdir -p "$T/scenarios"
    [ -f "$T/scenarios/$(basename "$file")" ] || cp "$file" "$T/scenarios/"
    split_cases "$T/scenarios/$(basename "$file")" | awk -F'\t' -v pattern="$pattern" 'pattern == "" || $6 ~ pattern'
  done
}

# The last run's failures first with $1 "first", alone with "only"; then jobs that run alone, then longest first by the last time each took, those never timed before the rest.
# A job runs alone where it says so (`# alone: why`), or where the shell last took a second to answer the probe in it,
# halfway to the 2 s it may: what other sessions take from the machine shows there first.
order_jobs() {
  awk -F'\t' -v OFS='\t' -v times="$hist/jobs.tsv" -v failures="$hist/failed" -v failed_jobs="$1" '
    BEGIN {
      while ((getline l < times) > 0) { split(l, f, "\t"); took[f[1] "\t" f[2]] = f[3]; peak[f[1] "\t" f[2]] = f[4] }
      while ((getline l < failures) > 0) failed[l] = 1
    }
    failed_jobs == "only" && !(key() in failed) { next }
    {
      if (peak[key()] >= 1000) $5 = 1
      print (failed_jobs == "first" && (key() in failed)) ? 1 : 0, $5, (key() in took) ? took[key()] : 1e9, $0
    }
    function key(  name, names) {
      name = $1
      sub(/.*\//, "", name)
      sub(/\.sh$/, "", name)
      split($6, names, " [|] ")
      return name "\t" names[1]
    }' | sort -t $'\t' -s -k1,1nr -k2,2nr -k3,3nr | cut -f4-
}

# The scenarios that exercise a directory of the shell; none for one this does not know.
component_scenarios() {
  case $1 in
    bar) echo tray hotplug workspaces cursors design controls chaos interactions idle notifications ;;
    center) echo notifications history motion cursors design hotplug chaos interactions idle failures ;;
    controls) echo controls caffeine cursors design chaos osd privacy interactions notifications ;;
    idle) echo idle chaos ;;
    launcher) echo launcher hotplug cursors design failures interactions chaos binds ;;
    notifications) echo notifications history cursors design chaos hotplug motion interactions controls failures ;;
    osd) echo osd motion design ;;
    power) echo interactions hotplug cursors design binds controls ;;
    shortcuts) echo hotplug cursors design binds failures ;;
    weather) echo failures design cursors notifications history motion ;;
  esac
}

# The directories a common/ type reaches, through the common/ types that use it; "all" if shell.qml uses one.
common_users() {
  local queue=("$1") visited=" $1 " name file rel
  while [ ${#queue[@]} -gt 0 ]; do
    name=${queue[0]}
    queue=("${queue[@]:1}")
    while IFS= read -r file; do
      rel=${file#"$src"/}
      case $rel in
        "common/$name.qml") ;;
        common/*.qml)
          file=$(basename "$rel" .qml)
          [[ $visited == *" $file "* ]] || { visited+="$file "; queue+=("$file"); }
          ;;
        */*) echo "${rel%%/*}" ;;
        *) echo all ;;
      esac
    done < <(grep -rlw --include='*.qml' -e "$name" "$src" || true)
  done | sort -u
}

# What a change in the checkout could break, by the components each scenario exercises; anything not listed here runs them all.
# The probe and gallery are in every case, so they add nothing beside another change, and run everything alone.
changed_scenarios() {
  local path dir comp all=0 probe=0 picked=() comps=()
  while IFS= read -r path; do
    case $path in
      *.md) ;;
      modules/features/hyprland/tests/scenarios/*.sh) picked+=("$(basename "$path" .sh)") ;;
      modules/features/hyprland/tests/Probe*.qml | modules/features/hyprland/tests/invariants.jq) probe=1 ;;
      modules/features/hyprland/tests/Gallery*.qml) picked+=(cursors design) ;;
      modules/features/hyprland/tests/networkmanager.py | modules/features/hyprland/tests/upower.py) picked+=(controls chaos) ;;
      modules/features/hyprland/tests/bluez.py | modules/features/hyprland/tests/mpris.py) picked+=(controls chaos cursors design) ;;
      modules/features/hyprland/tests/tray.qml | modules/features/hyprland/tests/trays.qml) picked+=(tray cursors design hotplug chaos) ;;
      modules/features/hyprland/tests/logind.py) picked+=(interactions) ;;
      modules/features/hyprland/scripts/camera-users.c) picked+=(privacy design) ;;
      modules/features/hyprland/scripts/backlight-watch.sh) picked+=(osd controls design) ;;
      modules/features/hyprland/quickshell/common/*.qml)
        # The gallery, in cursors and design, shows every piece.
        picked+=(cursors design)
        mapfile -t -O "${#comps[@]}" comps < <(common_users "$(basename "$path" .qml)")
        ;;
      modules/features/hyprland/quickshell/*/*)
        dir=${path#modules/features/hyprland/quickshell/}
        comps+=("${dir%%/*}")
        ;;
      *) all=1 ;;
    esac
  done < <(git -C "$repo" diff --name-only HEAD && git -C "$repo" ls-files --others --exclude-standard)
  for comp in "${comps[@]}"; do
    dir=$(component_scenarios "$comp")
    if [ -z "$dir" ]; then all=1; else read -ra dir <<< "$dir"; picked+=("${dir[@]}"); fi
  done
  if [ $all = 1 ] || { [ $probe = 1 ] && [ ${#picked[@]} = 0 ]; }; then
    echo "$tests"/scenarios/*.sh
  elif [ ${#picked[@]} -gt 0 ]; then
    printf '%s\n' "${picked[@]}" | sort -u
  fi
}

# Sessions side by side: a core or two each while busy, and a qs that may peak at a GiB.
default_jobs() {
  local cores memory
  cores=$(nproc)
  memory=$(awk '/MemAvailable/ { print int($2 / 1024) }' /proc/meminfo)
  awk -v cores="$cores" -v memory="$memory" 'BEGIN { n = int(cores / 2); m = int((memory - 4096) / 1536); if (m < n) n = m; print n < 1 ? 1 : n }'
}

# A session for `run`, up if it is not, with the checkout's QML in it.
prepare() {
  local build
  if running; then
    read -r build < "$T/build"
    fakes "$build"
  else
    up
  fi
  ln -sfn "$self" "$T/bin/qst"
  mkdir -p "$T/tests"
  : > "$T/timings.tsv"
  rm -f "$T/case"
  stop_qs
  sync_source
  start_qs
}

# The cases on REV's QML with the checkout's tests, in this session, which goes back to the checkout's QML after.
red() {
  local rev=HEAD tree=$T/red status=0
  if [ $# -gt 1 ] && [[ $1 != *:* ]] && [ ! -f "$1" ] && [ ! -f "$tests/scenarios/${1%.sh}.sh" ]; then
    rev=$1
    shift
  fi
  [ $# -gt 0 ] || die "red [REV] FILE[:CASE-REGEX]..."
  git -C "$repo" rev-parse -q --verify "$rev^{commit}" > /dev/null || die "no revision $rev"
  rm -rf "$tree"
  mkdir -p "$tree/modules/features/hyprland"
  git -C "$repo" archive "$rev" modules/features/hyprland/quickshell | tar -x -C "$tree"
  cp -r "$tests" "$tree/modules/features/hyprland/tests"
  if ! running; then
    QS_TEST_BUILD=$(build)
    export QS_TEST_BUILD
  fi
  QS_TEST_RED=$rev QS_TEST_REPO=$tree "$self" run -j 1 "$@" || status=$?
  rm -rf "$tree"
  if running; then
    stop_qs
    sync_source
    start_qs > /dev/null
  fi
  return $status
}

# One job in this session: its file's lines before the first case, then its own, each at its line in the file.
run_job() {
  local file=$1 prelude=$2 first=$3 last=$4 key=$5 name script status=0
  name=$(basename "$file" .sh)
  script=$T/tests/$name.$first.sh
  awk -v prelude="$prelude" -v first="$first" -v last="$last" '{ print (NR <= prelude || (NR >= first && NR <= last)) ? $0 : "" }' "$file" > "$script"
  # Read before the script by its bash alone: the line that failed, as set -e exits without saying.
  cat > "$T/tests/errexit.sh" << 'ERREXIT'
unset BASH_ENV
set -E
failed_at() {
  [ "$BASHPID" = $$ ] || return 0
  local at="line ${BASH_LINENO[0]}"
  [ "${#FUNCNAME[@]}" -le 2 ] || at+=" in ${FUNCNAME[1]}, called at line ${BASH_LINENO[-2]}"
  printf 'qs-test: %s.sh %s exited %s: %.200s\n' "$QST_FILE" "$at" "$1" "$2" >&2
}
trap 'failed_at $? "$BASH_COMMAND"' ERR
ERREXIT
  export QS_TEST_DIR=$T QS_TEST_REPO=$repo QS_TEST_HOST=$host
  rm -f "$T/case" "$T/trace.log"
  touch "$T/timings.tsv"
  local lines peak
  lines=$(wc -l < "$T/timings.tsv")
  ms
  local began=$REPLY
  (enter && QST_FILE=$name BASH_ENV=$T/tests/errexit.sh bash -euo pipefail "$script" && QST_FILE=$name "$self" check) || status=$?
  if [ $status != 0 ] && [ -s "$T/trace.log" ]; then
    echo "qs-test: the case's last qst calls:"
    tail -n 6 "$T/trace.log"
  fi
  rm -f "$T/case"
  peak=$(tail -n +$((lines + 1)) "$T/timings.tsv" | awk -F'\t' '$3 == "snapshot" && $5 > peak { peak = $5 } END { print peak + 0 }')
  ms
  QST_FILE=$name timing job $((REPLY - began)) "$key"$'\t'"$peak"
  restore_tools
  return $status
}

# Jobs spread over N sessions, each a QS_TEST_DIR of its own ($T itself when N is 1, else $T/w1 …); a line as each finishes.
run_tests() {
  local workers=() selected=() files=() n="" fail_fast=0 failed_jobs=all changed=0 arg w k
  while [ $# -gt 0 ]; do
    case $1 in
      -j) n=$2; shift ;;
      -j*) n=${1#-j} ;;
      --fail-fast) fail_fast=1 ;;
      --failed) failed_jobs=only ;;
      --failed-first) failed_jobs=first ;;
      --changed) changed=1 ;;
      -*) die "run [-j N] [--fail-fast] [--failed|--failed-first] [--changed] [FILE[:CASE-REGEX]...]" ;;
      *) selected+=("$1") ;;
    esac
    shift
  done
  if [ $changed = 1 ]; then
    while IFS= read -r arg; do [ -n "$arg" ] && selected+=("$arg"); done < <(changed_scenarios | tr ' ' '\n')
    [ ${#selected[@]} -gt 0 ] || { echo "nothing changed that a scenario exercises"; return 0; }
  fi
  [ ${#selected[@]} -gt 0 ] || selected=("$tests"/scenarios/*.sh)
  mkdir -p "$T" "$hist"
  # Held by this run alone: the sessions it starts close it, or one left up would hold it for good.
  exec 9> "$T/run.lock"
  flock -n 9 || die "another run is using $T"
  local queue=()
  rm -rf "$T/scenarios"
  mapfile -t queue < <(select_jobs "${selected[@]}" | order_jobs $failed_jobs)
  if [ ${#queue[@]} = 0 ]; then
    [ $failed_jobs != only ] || { echo "no failures left from the last run"; return 0; }
    die "no case matches ${selected[*]}"
  fi
  mapfile -t files < <(printf '%s\n' "${queue[@]}" | cut -f1 | sort -u)
  lint_scenarios "${files[@]}"
  n=${n:-$(default_jobs)}
  [ "$n" -le ${#queue[@]} ] || n=${#queue[@]}
  if [ "$n" -le 1 ]; then
    workers=("$T")
  else
    for k in $(seq "$n"); do workers+=("$T/w$k"); done
  fi

  ms
  local run_began=$REPLY pids=() status=0
  # One build for every session that has to come up.
  for w in "${workers[@]}"; do
    if ! QS_TEST_DIR=$w "$self" status | grep -q '^up'; then
      QS_TEST_BUILD=${QS_TEST_BUILD:-$(build)}
      export QS_TEST_BUILD
      break
    fi
  done
  for w in "${workers[@]}"; do
    mkdir -p "$w"
    QS_TEST_DIR=$w "$self" prepare > "$w.prepare.log" 2>&1 9>&- &
    pids+=($!)
  done
  for k in "${!pids[@]}"; do
    wait "${pids[$k]}" || { tail -15 "${workers[$k]}.prepare.log" >&2; die "session ${workers[$k]} did not come up"; }
  done
  echo "${#queue[@]} jobs on ${#workers[@]} sessions"

  local -A job_of=() worker_of=() began_of=() stopped=()
  [ "${#workers[@]}" = 1 ] || : > "$T/timings.tsv"
  local idle=("${workers[@]}") next=0 stop=0 failed=0 done_pid file prelude first last names log took key load alone solo=""
  : > "$T/failed"
  while :; do
    while [ $stop = 0 ] && [ -z "$solo" ] && [ ${#idle[@]} -gt 0 ] && [ $next -lt ${#queue[@]} ]; do
      IFS=$'\t' read -r file prelude first last alone names <<< "${queue[$next]}"
      # Once nothing else runs, and nothing starts beside it, so what it times is the machine's as a lone session had it.
      if [ "$alone" = 1 ]; then
        [ ${#job_of[@]} = 0 ] || break
        solo=pending
      fi
      w=${idle[0]}
      idle=("${idle[@]:1}")
      mkdir -p "$w/tests"
      # A session of its own, so --fail-fast can stop the whole job.
      QS_TEST_DIR=$w setsid "$self" job "$file" "$prelude" "$first" "$last" "${names%% | *}" > "$w/tests/$(basename "$file" .sh).$first.log" 2>&1 9>&- < /dev/null &
      job_of[$!]=$next
      worker_of[$!]=$w
      ms
      began_of[$!]=$REPLY
      [ "$solo" != pending ] || solo=$!
      next=$((next + 1))
    done
    [ ${#job_of[@]} -gt 0 ] || break
    status=0
    wait -n -p done_pid "${!job_of[@]}" || status=$?
    read -r load _ < /proc/loadavg
    timing load "${load/./}"
    ms
    took=$(awk -v ms=$((REPLY - began_of[$done_pid])) 'BEGIN { printf "%.1f", ms / 1000 }')
    IFS=$'\t' read -r file prelude first last alone names <<< "${queue[${job_of[$done_pid]}]}"
    [ "$solo" != "$done_pid" ] || solo=""
    w=${worker_of[$done_pid]}
    file=$(basename "$file" .sh)
    log=$w/tests/$file.$first.log
    if [ -n "${stopped[$done_pid]:-}" ]; then
      echo "stop $file: ${names%% | *} ($took s)"
    elif [ -n "${QS_TEST_RED:-}" ]; then
      # On the old QML a case must fail; the line it failed at shows whether for the right reason.
      if [ $status = 0 ]; then
        failed=1
        echo "FAIL $file: ${names%% | *} passes on $QS_TEST_RED, so it does not catch the bug ($took s)"
      else
        echo "ok   $file: ${names%% | *} fails on $QS_TEST_RED ($took s, $log)"
        sed '/^qs-test: the case.s last qst calls:$/,$d; /^== /d' "$log" | tail -4 | cut -c1-300 | sed 's/^/     /'
      fi
    elif [ $status = 0 ]; then
      echo "ok   $file: ${names%% | *}$([ "$names" = "${names%% | *}" ] || echo " and $(grep -c '^== ' "$log" | awk '{ print $1 - 1 }') more") ($took s)"
    else
      failed=1
      printf '%s\t%s\n' "$file" "${names%% | *}" >> "$T/failed"
      echo "FAIL $file, in: $(grep '^== ' "$log" | tail -1 | cut -c4-) ($took s, $log)"
      grep -v '^== ' "$log" | tail -15 | sed 's/^/     /'
      if [ $fail_fast = 1 ] && [ $stop = 0 ]; then
        stop=1
        for key in "${!job_of[@]}"; do
          [ "$key" = "$done_pid" ] && continue
          stopped[$key]=1
          kill -- -"$key" 2> /dev/null || true
        done
      fi
    fi
    idle+=("$w")
    unset "job_of[$done_pid]" "worker_of[$done_pid]" "began_of[$done_pid]" "stopped[$done_pid]"
  done
  [ $stop = 0 ] || echo "stopped at the first failure, $((${#queue[@]} - next)) jobs not started"

  if [ "${#workers[@]}" -gt 1 ]; then cat "${workers[@]/%//timings.tsv}" >> "$T/timings.tsv"; fi
  ms
  timing run $((REPLY - run_began))
  [ -n "${QS_TEST_RED:-}" ] && return $failed
  remember_run
  report "$T/timings.tsv"
  return $failed
}

# Each job's time for the next run's order, and the failures: this run's, and the last one's that did not run again.
remember_run() {
  awk -F'\t' -v OFS='\t' '$3 == "job" { print $1, $5, $4, $6 }' "$T/timings.tsv" > "$T/times.new"
  awk -F'\t' -v OFS='\t' 'FNR == NR { run[$1 "\t" $2] = 1; print; next } !(($1 "\t" $2) in run)' "$T/times.new" "$hist/jobs.tsv" 2> /dev/null > "$hist/jobs.tsv.new" || true
  mv "$hist/jobs.tsv.new" "$hist/jobs.tsv"
  { cat "$T/failed"; awk -F'\t' 'FNR == NR { run[$1 "\t" $2] = 1; next } !(($1 "\t" $2) in run)' "$T/times.new" "$hist/failed" 2> /dev/null || true; } > "$hist/failed.new"
  mv "$hist/failed.new" "$hist/failed"
  rm -f "$T/times.new"
}

# The slowest cases, and where the time went: resets, waits, stays and the cases' own work.
report() {
  [ -s "$1" ] || return 0
  echo "slowest cases:"
  awk -F'\t' '$3 == "case" { printf "%8.1f s  %s: %s\n", $4 / 1000, $1, $2 }' "$1" | sort -rn | awk 'NR <= 15'
  awk -F'\t' -v cores="$(nproc)" '
    $3 == "case" { cases++; total += $4; files[$1] += $4 }
    $3 == "run" { run = $4 }
    $3 ~ /^reset:/ { reset += $4; phases[substr($3, 7)] += $4 }
    $3 ~ /^reset~/ { beside[substr($3, 7)] += $4 }
    $3 == "wait" { wait += $4 }
    $3 == "stays" { stays += $4 }
    $3 == "snapshot" { snaps++; snapping += $4; if ($5 > answered) answered = $5 }
    $3 == "load" && $4 > load { load = $4 }
    function share(x) { return total ? sprintf("%.0f %%", 100 * x / total) : "-" }
    END {
      line = "files:"
      for (f in files) line = line sprintf(" %s %.0f s,", f, files[f] / 1000)
      print substr(line, 1, length(line) - 1)
      printf "phases of reset:"
      for (p in phases) printf " %s %.1f s", p, phases[p] / 1000
      if (length(beside)) printf ", of which side by side:"
      for (p in beside) printf " %s %.1f s", p, beside[p] / 1000
      printf "\n%d cases, %.0f s (the run %.0f s): reset %s, waits %s, stays %s, the cases themselves %s\n", cases, total / 1000, run / 1000, share(reset), share(wait), share(stays), share(total - reset - wait - stays)
      if (snaps) printf "%d snapshots, %.0f ms each, %s of the time\n", snaps, snapping / snaps, share(snapping)
      if (snaps) printf "the probe answered within %d ms (2000 allowed)%s\n", answered, load ? sprintf("; load average up to %.1f on %d cores", load / 100, cores) : ""
    }' "$1"
}

# Assert with wait and stays: a sleep only guesses how long something takes, unless its line says why it is one.
lint_scenarios() {
  local found
  found=$(grep -nE '(^|[;&|(]|then|do)[[:space:]]*sleep[[:space:]]' "$@" | grep -v '# sleep: ' || true)
  [ -z "$found" ] || die "scenarios sleep where they should wait (or say why after '# sleep: '):"$'\n'"$found"
}

# TOOL fails as MODE (exit, crash, missing, garbage) wherever the shell runs it, until `fail TOOL off` or a reset.
fail_tool() {
  local tool=$1 mode=$2 bin=$T/bin
  mkdir -p "$bin/.real"
  # Only what `fail` put there goes, so the fakes the session stands in for real tools stay.
  if [ "$mode" = off ]; then
    if [ -e "$bin/.real/$tool" ]; then
      mv "$bin/.real/$tool" "$bin/$tool"
    elif [ -e "$bin/.real/$tool.none" ]; then
      rm -f "$bin/$tool" "$bin/.real/$tool.none"
    fi
    return
  fi
  if [ ! -e "$bin/.real/$tool" ] && [ ! -e "$bin/.real/$tool.none" ]; then
    if [ -e "$bin/$tool" ]; then mv "$bin/$tool" "$bin/.real/$tool"; else : > "$bin/.real/$tool.none"; fi
  fi
  case $mode in
    exit) printf '#!/bin/sh\necho "%s $* (failing)" >> "%s/actions.log"\necho "%s: failed for qst" >&2\nexit 1\n' "$tool" "$T" "$tool" > "$bin/$tool" ;;
    crash) printf '#!/bin/sh\necho "%s $* (crashing)" >> "%s/actions.log"\nkill -SEGV $$\n' "$tool" "$T" > "$bin/$tool" ;;
    # QProcess finds it on PATH and then cannot start it, as with a program that is not installed.
    missing) printf '#!/nonexistent/qst-missing\n' > "$bin/$tool" ;;
    garbage) printf '#!/bin/sh\necho "%s $* (garbage)" >> "%s/actions.log"\necho "{\\"garbage"\n' "$tool" "$T" > "$bin/$tool" ;;
    *) die "fail TOOL exit|crash|missing|garbage|off" ;;
  esac
  chmod +x "$bin/$tool"
}

restore_tools() {
  local saved
  for saved in "$T"/bin/.real/*; do
    [ -e "$saved" ] || continue
    saved=$(basename "$saved" .none)
    fail_tool "$saved" off
  done
}

# The cursor Qt set last, as "shape address": it logs each decision, naming the item behind it ("A -> B" lines are an item's own cursor changing).
cursor_now() {
  grep -a 'qt\.quick\.hover\.cursor' "$T/qs.log" | grep -aE '(^|[^n])setting cursor|unsetting cursor' | tail -1 | sed -E '
    s/.*unsetting cursor.*/Arrow -/
    s/.*setting cursor QCursor\(Qt::CursorShape\(Qt::([A-Za-z]+)Cursor\)\) from [A-Za-z0-9_:]+\((0x[0-9a-f]+)[^ ]* or [A-Za-z0-9_:]+\((0x[0-9a-f]+).*/\1 \2 \3/
    s/^([A-Za-z]+) 0x0 /\1 /; s/^([A-Za-z]+) (0x[0-9a-f]+) 0x[0-9a-f]+$/\1 \2/
    s/^PointingHand /hand /; s/^Arrow /arrow /; s/^ClosedHand /closed /; s/^OpenHand /open /; s/^IBeam /text /'
}

# Hovers X Y, nudging the pointer so Qt looks again, and prints the cursor: shape, address and what set it.
cursor_at() {
  local shape address what
  pointer "$1" "$2"
  input move 1 0
  input move -1 0
  sleep 0.3
  read -r shape address <<< "$(cursor_now)"
  what=-
  if [ "${address:--}" != - ]; then
    what=$(timeout 5 qs ipc -p "$T/shell" call probe describe "$address")
    # Qt logs a new decision only for a new item; one changing its own cursor, a card being dragged, keeps it.
    shape=$(jq -r --arg shape "$shape" ".shape // \$shape" <<< "$what")
  fi
  echo "$shape ${address:--} $what"
}

# The mouse areas on screen in layout coordinates, each window placed by its layer: x, y, label, enabled, takes a click, asks for a hand.
areas() {
  local areas layers
  enter
  areas=$(timeout 5 qs ipc -p "$T/shell" call probe areas)
  layers=$("$HC" layers -j)
  jq -r --argjson layers "$layers" '
    (.scale | tonumber) as $scale | .areas[] as $a
    | [$layers[$a.screen].levels[][] | select(.namespace | startswith("quickshell:"))
       | select(((.w - $a.window[0] * $scale) | fabs) < 2 and ((.h - $a.window[1] * $scale) | fabs) < 2)][0] as $layer
    | select($layer)
    | [($layer.x + $a.x * $scale | floor), ($layer.y + $a.y * $scale | floor), $a.label, $a.enabled, $a.clicks, $a.hand] | @tsv' <<< "$areas"
}

# Where the area named [WINDOW:]NAME is, as "x y": its objectName (pill:wifi, action:Clear), an enabled one first; WINDOW starts upper case.
# Missing, the names there, so a test that lost its target says what it could have clicked.
area_at() {
  local window="" name=$1 found
  if [[ $1 =~ ^([A-Z][A-Za-z0-9]*):(.+)$ ]]; then
    window=${BASH_REMATCH[1]}
    name=${BASH_REMATCH[2]}
  fi
  found=$(areas | awk -F'\t' -v window="$window" -v name="$name" '
    window != "" && index($3, window "/") != 1 { next }
    { at = index($3, ":" name) }
    at && substr($3, at + length(name) + 1, 1) ~ /^( |$)/ {
      if ($4 == "true") { print $1, $2; hit = 1; exit }
      if (!fallback) fallback = $1 " " $2
    }
    { if (index($3, ":")) names[substr($3, index($3, ":") + 1)] = 1 }
    END { if (hit) exit; if (fallback) print fallback; else for (n in names) print "\t" n }')
  if [ -n "$found" ] && [ "${found:0:1}" != $'\t' ]; then
    echo "$found"
    return
  fi
  die "no area named $name${window:+ in $window}; there: $(cut -f2 <<< "$found" | sort | head -n 30 | paste -sd ',' | sed 's/,/, /g')"
}

# Every enabled mouse area that takes a click and asks for a hand gets one: something laid over it must not set an arrow of its own.
cursor_sweep() {
  local x y label enabled clicks hand shape address what bad=0
  while IFS=$'\t' read -r x y label enabled clicks hand; do
    [ "$enabled" = true ] && [ "$clicks" = true ] && [ "$hand" = true ] || continue
    read -r shape address what <<< "$(cursor_at "$x" "$y")"
    if [ "$shape" != hand ]; then
      echo "$label asks for a hand at $x $y, but $( [ "$address" = - ] && echo "no item" || echo "$what") sets $shape" >&2
      bad=1
    fi
  done < <(areas | awk -F "\t" -v window="${1:-}" 'window == "" || index($3, window "/") == 1')
  [ $bad = 0 ] || exit 1
  return $bad
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
case $cmd in case | check | trace | job | run | red | prepare) ;; *) trace "$cmd" "$@" ;; esac
case $cmd in
  up) up ;;
  down) down ;;
  status) if running; then echo "up in $T, qs $(testqs)"; else echo down; fi ;;
  sync) need_up; case_check; stop_qs; sync_source; start_qs ;;
  restart) need_up; case_check; stop_qs; start_qs ;;
  lint) qs-lint "$(readlink -f "$(build)/shell")" ;;
  ipc) need_up; enter; timeout 5 qs ipc -p "$T/shell" call "$@" ;;
  gallery) need_up; enter; timeout 5 qs ipc -p "$T/shell" call panels open gallery > /dev/null ;;
  state) need_up; state "$@" ;;
  wait) need_up; wait_for "$@" ;;
  stays) need_up; stays "$@" ;;
  reset) need_up; reset ;;
  case)
    need_up
    case_check
    echo "== $*"
    echo "$*" > "$T/case"
    ms
    echo "$REPLY" > "$T/case-start"
    : > "$T/trace.log"
    : > "$T/expected"
    reset
    ;;
  check) need_up; case_check ;;
  expect)
    need_up
    kind=must
    [ "${1:-}" = --may ] && kind=may && shift
    [ $# -eq 1 ] || die "expect [--may] REGEX"
    printf "%s\t%s\n" "$kind" "$1" >> "$T/expected"
    ;;
  census) need_up; enter; timeout 5 qs ipc -p "$T/shell" call probe census | jq -r ".[]" ;;
  motion)
    need_up
    enter
    case ${1:-} in
      start) timeout 5 qs ipc -p "$T/shell" call probe motion true > /dev/null ;;
      stop)
        motion=$(timeout 5 qs ipc -p "$T/shell" call probe motion false)
        echo "$motion"
        jq -e ".problems == []" <<< "$motion" > /dev/null || { jq -r ".problems[]" <<< "$motion" >&2; exit 1; }
        ;;
      *) die "motion start|stop" ;;
    esac
    ;;
  cursor)
    need_up
    enter
    read -r shape address what <<< "$(cursor_at "$1" "$2")"
    echo "$shape $address $what"
    [ -z "${3:-}" ] || [ "$shape" = "$3" ] || die "the cursor at $1 $2 is $shape, not $3"
    ;;
  cursors) need_up; cursor_sweep "$@" ;;
  areas) need_up; areas | awk -F "\t" -v pattern="${1:-.}" '$3 ~ pattern' ;;
  area) need_up; [ $# -eq 1 ] || die "area [WINDOW:]NAME"; area_at "$1" ;;
  trace) cat "$T/trace.log" 2> /dev/null || true ;;
  fail) need_up; [ $# -eq 2 ] || die "fail TOOL exit|crash|missing|garbage|off"; fail_tool "$1" "$2" ;;
  run) mkdir -p "$hist"; run_tests "$@" 2>&1 | tee "$hist/last-run.log" ;;
  red) red "$@" ;;
  job) need_up; run_job "$@" ;;
  prepare) prepare ;;
  timings) report "$T/timings.tsv" ;;
  jobs) [ $# -gt 0 ] || set -- "$tests"/scenarios/*.sh; select_jobs "$@" | order_jobs all | awk -F"\t" '{ sub(/.*\//, "", $1); printf "%s:%d-%d (prelude 1-%d)%s  %s\n", $1, $3, $4, $2, $5 ? ", alone" : "", $6 }' ;;
  key) need_up; input key "$@" ;;
  hold) need_up; input hold "$1" "$2" ;;
  type) need_up; input type "$*" ;;
  pointer) need_up; pointer "$1" "$2" ;;
  move) need_up; input move "$1" "$2" ;;
  click)
    need_up
    button=left
    case ${1:-} in left | right | middle) button=$1; shift ;; esac
    if [ $# = 1 ] || [ $# = 3 ]; then
      at=$(area_at "$1")
      read -r x y <<< "$at"
      pointer $((x + ${2:-0})) $((y + ${3:-0}))
    elif [ $# = 2 ]; then
      pointer "$1" "$2"
    fi
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
  spin) need_up; input spin "$@" ;;
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
      stop) printf "may\t%s\n" "Failed to connect pipewire context" "Pipewire error on object 0 with code -32" >> "$T/expected"; pw_stop ;;
      restart) printf "may\t%s\n" "Failed to connect pipewire context" "Pipewire error on object 0 with code -32" >> "$T/expected"; pw_stop; pw_start ;;
      *) die "pipewire start|stop|restart" ;;
    esac
    ;;
  network) need_up; enter; network "$@" ;;
  battery) need_up; enter; battery "$@" ;;
  bluetooth) need_up; enter; bluetooth "$@" ;;
  player) need_up; enter; player "$@" ;;
  backlight) need_up; [ $# -ge 2 ] || die "backlight NAME VALUE [MAX], or NAME remove"; backlight "$@" ;;
  camera) need_up; enter; camera "$@" ;;
  spawn) need_up; enter; setsid "$@" >> "$T/spawn.log" 2>&1 < /dev/null & echo $! >> "$T/launched" ;;
  flood) need_up; enter; qs-flood "$@" ;;
  tray)
    need_up
    case "${1:-}" in
      log) grep -o 'qml: .*' "$T/tray.log" ;;
      add)
        [ $# -ge 2 ] || die "tray add NAME [COUNT]"
        enter
        mkdir -p "$T/trays"
        qs-tray "$2" "${3:-1}" >> "$T/tray.log" 2>&1 < /dev/null &
        echo $! > "$T/trays/$2.pid"
        ;;
      remove)
        [ $# -eq 2 ] && [ -s "$T/trays/$2.pid" ] || die "tray remove NAME, one added"
        kill "$(cat "$T/trays/$2.pid")" 2> /dev/null || true
        rm -f "$T/trays/$2.pid"
        ;;
      clear) trays_reset ;;
      "")
        enter
        [ -s "$T/tray.pid" ] && kill "$(cat "$T/tray.pid")" 2> /dev/null || true
        qs-tray > "$T/tray.log" 2>&1 < /dev/null &
        echo $! > "$T/tray.pid"
        ;;
      *) die "tray [log|add NAME [COUNT]|remove NAME|clear]" ;;
    esac
    ;;
  x) need_up; enter; exec "$@" ;;
  log) cat "$T/qs.log" ;;
  hyprlog) enter; cat "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" ;;
  problems) problems ;;
  actions) cat "$T/actions.log" ;;
  help | -h | --help) usage ;;
  *) usage >&2; exit 1 ;;
esac
