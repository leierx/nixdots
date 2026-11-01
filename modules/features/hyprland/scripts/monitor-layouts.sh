# usage: monitor-layouts; $profiles_dir is set by the nix wrapper
shopt -s nullglob
profiles=("$profiles_dir"/*.json)
((${#profiles[@]})) || exit 0

name=$(jq -r .name "${profiles[@]}" | sort |
  rofi -dmenu -i -theme-str 'entry {placeholder: "Monitor layout";}') || exit 0

if ! out=$(hyprmoncfg apply --confirm-timeout 0 "$name" 2>&1); then
  notify-send -u critical "hyprmoncfg: $name" "$out"
fi
