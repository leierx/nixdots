#!/bin/sh
# new-board.sh SLUG: ~/.local/share/design-board/SLUG with the engine refreshed and, the first time, the starter board.
set -eu
usage() { echo "usage: new-board.sh SLUG (lowercase letters, digits and -)" >&2; exit 2; }
[ $# -eq 1 ] || usage
case $1 in '' | *[!a-z0-9-]*) usage ;; esac
skill=$(cd "$(dirname "$0")" && pwd)
dir=${XDG_DATA_HOME:-$HOME/.local/share}/design-board/$1
mkdir -p "$dir"
# Copies, not links: the skill lives in a read-only store path that moves with every rebuild.
for f in index.html engine.js engine.css; do install -m 644 "$skill/engine/$f" "$dir/$f"; done
for f in board.js board.css; do
  [ -e "$dir/$f" ] && continue
  tmp=$(mktemp "$dir/.$f.XXXXXX")
  sed "s/SLUG/$1/" "$skill/starter/$f" >"$tmp" || { rm -f "$tmp"; exit 1; }
  chmod 644 "$tmp"
  mv "$tmp" "$dir/$f"
done
chmod u+w "$dir"/board.js "$dir"/board.css
echo "$dir"
