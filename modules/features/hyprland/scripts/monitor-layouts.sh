# $profiles_dir is set by the nix wrapper
shopt -s nullglob
profiles=("$profiles_dir"/*.json)
((${#profiles[@]})) || exit 0

# stderr apart: a warning there would break the JSON
err=$(mktemp)
trap 'rm -f "$err"' EXIT
if ! status=$(hyprmoncfg status --json 2>"$err"); then
  notify-send -u critical "hyprmoncfg status" "$(<"$err")"
  exit 1
fi
recommended=$(jq -r '.recommended_profile.name // empty' <<<"$status")
# the daemon keeps a hand-picked profile until hotplug; this applies what it would pick
auto="auto${recommended:+ ($recommended)}"

name=$({
  [[ -n $recommended ]] && echo "$auto"
  jq -r .name "${profiles[@]}" | sort
} | rofi -dmenu -i -theme-str 'entry {placeholder: "Monitor layout";}') || exit 0
[[ $name == "$auto" ]] && name=$recommended

if ! out=$(hyprmoncfg apply --confirm-timeout 0 "$name" 2>&1); then
  notify-send -u critical "hyprmoncfg: $name" "$out"
fi
