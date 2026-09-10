#!/bin/sh
set -eu

filepath="$HOME/Pictures/screenshots/$(date +%Y%m%d-%H%M%S)-$$.png"
mkdir -p "$(dirname "$filepath")"

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
grim -g "$g" "$filepath"
