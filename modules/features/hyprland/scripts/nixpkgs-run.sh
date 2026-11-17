if [ $# -ne 3 ]; then
  echo "usage: nixpkgs-run <rev> <attr> <program>" >&2
  exit 2
fi
rev=$1
attr=$2
program=$3

log=$(mktemp)
trap 'rm -f "$log"' EXIT

id=$(notify-send -p -e -u low -a nixpkgs "Fetching $attr" "nixpkgs ${rev:0:12}") || id=0
fail() {
  notify-send -r "$id" -u critical -a nixpkgs "$1" "$(tail -n 4 "$log")"
  exit 1
}

if ! paths=$(NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --print-out-paths --impure "github:NixOS/nixpkgs/$rev#$attr" 2>"$log"); then
  fail "$attr failed to build"
fi

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

runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
config=${XDG_CONFIG_HOME:-$HOME/.config}

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
  --property="BindPaths=-$runtime/${WAYLAND_DISPLAY:-wayland-0}"
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

if $gui; then
  "${sandbox[@]}" "$exe" 2>"$log" || fail "$attr failed to start"
else
  rm -f "$log"
  # A command that is over at once, or failed, stays on screen until Enter.
  # shellcheck disable=SC2016
  exec "$terminal" start --always-new-process -- "$BASH" -c '
    start=$SECONDS
    "$@"
    status=$?
    if [ "$status" -ne 0 ] || [ $((SECONDS - start)) -lt 5 ]; then
      printf "\n[%s exited with %s; Enter closes]" "$0" "$status"
      read -r _
    fi' "$attr" "${sandbox[@]}" --pty --wait --setenv=COLORTERM=truecolor "$exe"
fi
