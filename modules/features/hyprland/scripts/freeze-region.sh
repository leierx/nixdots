# usage: freeze-region copy|save; $screenshot_dir is set by the nix wrapper
mode=${1:-}
case "$mode" in
copy | save) ;;
*)
  echo "usage: freeze-region copy|save" >&2
  exit 2
  ;;
esac

tmpdir=$(mktemp -d)
marker="$tmpdir/frozen"
wayfreeze --after-freeze-timeout 100 --hide-cursor --after-freeze-cmd "touch \"$marker\"" &
wp=$!

cleanup() {
  kill "$wp" 2>/dev/null || true
  rm -rf "$tmpdir"
}
trap cleanup EXIT

i=0
while [ ! -e "$marker" ] && kill -0 "$wp" 2>/dev/null && [ "$i" -lt 100 ]; do
  sleep 0.05
  i=$((i + 1))
done
[ -e "$marker" ] || exit 1
g=$(slurp -d)
[ -n "$g" ] || exit 1

if [ "$mode" = copy ]; then
  grim -g "$g" - | wl-copy --type image/png
else
  mkdir -p "$screenshot_dir"
  grim -g "$g" "$screenshot_dir/$(date +%Y%m%d-%H%M%S)-$$.png"
fi
