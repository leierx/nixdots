mode=${1:-}
case "$mode" in
copy | edit) ;;
*)
  echo "usage: freeze-region copy|edit" >&2
  exit 2
  ;;
esac

fail() {
  notify-send -a Screenshot -n accessories-screenshot -u critical "Screenshot Failed" "$1"
  exit 1
}

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
[ -e "$marker" ] || fail "The screen could not be frozen"
# Escape in slurp is no failure.
g=$(slurp -d) || exit 0
[ -n "$g" ] || exit 0

# ppm for Swappy: no encoding to wait on
if [ "$mode" = edit ]; then type=ppm; else type=png; fi
file="$tmpdir/shot.$type"
err=$(grim -t "$type" -g "$g" "$file" 2>&1) || fail "${err:-grim failed}"
kill "$wp" 2>/dev/null || true

if [ "$mode" = edit ]; then
  swappy --file "$file" || fail "Swappy failed"
else
  # Its server keeps any pipe open, so its error is not captured.
  wl-copy --type image/png < "$file" || fail "Could not copy it to the clipboard"
fi
