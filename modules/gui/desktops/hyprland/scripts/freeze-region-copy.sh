#!/bin/sh
set -eu

p=$(mktemp -u).fifo
mkfifo "$p"
wayfreeze --after-freeze-timeout 100 --hide-cursor --after-freeze-cmd "echo > $p" &
wp=$!

cleanup() {
  kill "$wp" 2>/dev/null || true
  rm -f "$p"
}
trap cleanup EXIT

read -r < "$p"
g=$(slurp -d)
[ -n "$g" ] || exit 1
grim -g "$g" - | wl-copy --type image/png
