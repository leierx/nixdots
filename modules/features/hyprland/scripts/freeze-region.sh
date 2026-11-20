# $screenshot_dir is set by the nix wrapper
mode=${1:-}
case "$mode" in
copy | save) ;;
*)
  echo "usage: freeze-region copy|save" >&2
  exit 2
  ;;
esac

notify() {
  notify-send -a Screenshot -n accessories-screenshot "$@"
}

fail() {
  notify -u critical "Screenshot failed" "$1"
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
[ -e "$marker" ] || fail "The screen could not be frozen."
# Escape in slurp is no failure.
g=$(slurp -d) || exit 0
[ -n "$g" ] || exit 0

if [ "$mode" = copy ]; then
  # The card's picture, for as long as the session; a newer copy's card replaces it.
  dir="$XDG_RUNTIME_DIR/screenshots"
  mkdir -p "$dir"
  rm -f "$dir"/copy-*.png
  file="$dir/copy-$(date +%Y%m%d-%H%M%S)-$$.png"
else
  mkdir -p "$screenshot_dir" || fail "Could not make $screenshot_dir."
  file="$screenshot_dir/$(date +%Y%m%d-%H%M%S)-$$.png"
fi

err=$(grim -g "$g" "$file" 2>&1) || fail "${err:-grim failed.}"
kill "$wp" 2>/dev/null || true

if [ "$mode" = copy ]; then
  # Its server keeps any pipe open, so its error is not captured.
  wl-copy --type image/png < "$file" || fail "Could not copy it to the clipboard."
  notify -t 3000 -h boolean:transient:true -h boolean:suppress-sound:true -i "file://$file" -h string:x-canonical-private-synchronous:screenshot "Screenshot copied to clipboard"
else
  # Each save keeps a card of its own, with its own file to open; the actions wait in the background.
  (
    action=$(notify -h boolean:transient:true -h boolean:suppress-sound:true -i "file://$file" -A default=Open -A open=Open -A "folder=Show in Folder" "Screenshot saved" "${file/#"$HOME"/\~}") || exit 0
    case "$action" in
    default | open) xdg-open "$file" ;;
    folder) xdg-open "$(dirname "$file")" ;;
    esac
  ) > /dev/null 2>&1 &
fi
