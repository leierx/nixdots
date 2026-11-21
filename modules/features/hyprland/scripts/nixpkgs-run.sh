if [ $# -ne 3 ]; then
  echo "usage: nixpkgs-run <rev> <attr> <program>" >&2
  exit 2
fi
rev=$1
attr=$2
program=$3

log=$(mktemp)
json=$(mktemp)
built=$(mktemp)
wayland=""
holder=""
cleanup() {
  rm -f "$log" "$json" "$built"
  if [ -n "$wayland" ]; then rm -rf "$wayland"; fi
  if [ -n "$holder" ]; then kill "$holder" 2>/dev/null || true; fi
}
trap cleanup EXIT

# Waits on the card, so one dismissed mid-build stays dismissed rather than coming back with the next update.
coproc card { notify-send -p -w -u low -t 0 -a nixpkgs -n nix-snowflake "Fetching $attr" "Evaluating nixpkgs ${rev:0:12}"; }
holder=$!
read -r id <&"${card[0]}" || id=0

fail() {
  notify-send -r "$id" -u critical -a nixpkgs -n nix-snowflake "$1" "$(tail -n 4 "$log")"
  exit 1
}

update() {
  if kill -0 "$holder" 2>/dev/null; then
    notify-send -r "$id" -u low -t 0 -a nixpkgs -n nix-snowflake "$@" || true
  fi
}

# Twice a second at most, and at once when the phase changes, since every update moves the card to the top.
report() {
  local percent finished expected running sizes phase shown="" last=0 now
  while IFS=$'\t' read -r percent finished expected running sizes; do
    if [ "$running" -gt 0 ] && [ "$expected" -gt 0 ]; then
      phase=build
    elif [ "$percent" -ge 0 ]; then
      phase=fetch
    else
      continue
    fi
    # The decimal separator follows the locale.
    now=${EPOCHREALTIME//[!0-9]/}
    if [ "$phase" = "$shown" ] && [ $((now - last)) -lt 500000 ]; then continue; fi
    shown=$phase
    last=$now
    if [ "$phase" = build ]; then
      update "Building $attr" "$finished of $expected${sizes:+ · $sizes downloaded}" -h "int:value:$((finished * 100 / expected))"
    else
      update "Fetching $attr" "$sizes" -h "int:value:$percent"
    fi
  done
}

if ! { NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --print-out-paths --impure --log-format internal-json "github:NixOS/nixpkgs/$rev#$attr" >"$built"; } 2>&1 |
  tee "$json" | jq -nrR --unbuffered -f "$progress" | report; then
  sed -n 's/^@nix //p' "$json" | jq -r 'select(.action == "msg" and .level == 0) | .msg' | sed 's/\x1b\[[0-9;]*m//g' >"$log"
  grep -v '^@nix ' "$json" >>"$log" || true
  fail "$attr failed to build"
fi
paths=$(<"$built")

# As `nix run` picks it, then a desktop entry for it decides between a window of its own and a terminal.
exe=""
gui=false
while read -r out; do
  if [ -z "$exe" ] && [ -x "$out/bin/$program" ]; then
    exe=$out/bin/$program
  fi
  for entry in "$out"/share/applications/*.desktop; do
    [ -f "$entry" ] || continue
    command=$(grep -m 1 '^Exec=' "$entry" || true)
    command=${command#Exec=}
    command=${command%% *}
    if [ "${command##*/}" = "$program" ] && ! grep -qx 'Terminal=true' "$entry"; then
      gui=true
    fi
  done
done <<<"$paths"

if [ -z "$exe" ]; then
  echo "no bin/$program in $paths" >"$log"
  fail "$attr has no program to run"
fi

# Its window, or its terminal, takes over from the card.
busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications CloseNotification u "$id" >/dev/null 2>&1 || true

runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
config=${XDG_CONFIG_HOME:-$HOME/.config}
display=${WAYLAND_DISPLAY:-wayland-0}

# Hyprland hides every protocol that could type into or capture other windows from a client on a security context's socket.
wayland=$(mktemp -d -p "$runtime" nixpkgs-run.XXXXXX)

# Writes land in tmpfs and go with it; the user manager implies PrivateUsers, so this needs no privileges.
sandbox=(
  systemd-run --user --quiet --collect --service-type=exec
  --description="nixpkgs#$attr"
  --working-directory="$HOME"
  --property=ProtectSystem=strict
  --property=PrivateTmp=yes
  --property="TemporaryFileSystem=$HOME:mode=0700"
  --property="TemporaryFileSystem=$runtime:mode=0700"
  # The daemon would let it write to the store, and the session and system buses would let it ask anything outside to.
  --property=InaccessiblePaths=-/nix/var/nix/daemon-socket
  --property=InaccessiblePaths=-/run/dbus
  --property="BindPaths=$wayland/socket:$runtime/$display"
  --property="BindPaths=-$runtime/pipewire-0"
  --property="BindPaths=-$runtime/pulse/native"
  --property=BindReadOnlyPaths=-/tmp/.X11-unix
  --property="BindReadOnlyPaths=-$config/gtk-3.0"
  --property="BindReadOnlyPaths=-$config/gtk-4.0"
  --property="BindReadOnlyPaths=-$config/fontconfig"
  --property="BindReadOnlyPaths=-$HOME/.icons"
)
for var in WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE; do
  if [ -n "${!var:-}" ]; then
    sandbox+=(--setenv="$var")
  fi
done

# Waited on, as the socket takes connections only while security-context runs.
if $gui; then
  security-context "$wayland/socket" "$attr" "${sandbox[@]}" --wait "$exe" 2>"$log" || fail "$attr stopped with an error"
else
  # A command that is over at once, or failed, stays on screen until Enter.
  # shellcheck disable=SC2016
  security-context "$wayland/socket" "$attr" "$terminal" start --always-new-process -- "$BASH" -c '
    start=$SECONDS
    "$@"
    status=$?
    if [ "$status" -ne 0 ] || [ $((SECONDS - start)) -lt 5 ]; then
      printf "\n[%s exited with %s; Enter closes]" "$0" "$status"
      read -r _
    fi' "$attr" "${sandbox[@]}" --pty --wait --setenv=COLORTERM=truecolor "$exe"
fi
