export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "every bind that reaches the shell opens a panel of its own, and closes it again"
opened=" "
while read -r combo; do
  qst key "$combo"
  qst wait '.panel != ""'
  panel=$(qst state .panel)
  case $opened in *" $panel "*) echo "$combo opens $panel, which another bind opened already"; exit 1 ;; esac
  opened+="$panel "
  qst key "$combo"
  qst wait '.panel == ""'
done < <(hyprctl binds -j | jq -r '.[] | select(.dispatcher == "HL.Dispatcher(global)" and (.key | startswith("XF86") | not))
  | [(if .modmask % 128 >= 64 then "super" else empty end), (if .modmask % 8 >= 4 then "ctrl" else empty end),
     (if .modmask % 16 >= 8 then "alt" else empty end), (if .modmask % 2 == 1 then "shift" else empty end), .key] | join("+")')
[ "$opened" != " " ] || { echo "no bind reaches the shell"; exit 1; }

qst case "a bind held down, as a key repeats, opens its panel once and leaves it open"
while read -r combo; do
  qst hold "$combo" 1200
  qst wait '.panel != ""'
  panel=$(qst state .panel)
  qst stays ".panel == $panel" 0.5
  qst ipc panels close > /dev/null
  qst wait '.panel == ""'
done < <(hyprctl binds -j | jq -r '.[] | select(.dispatcher == "HL.Dispatcher(global)" and (.key | startswith("XF86") | not))
  | [(if .modmask % 128 >= 64 then "super" else empty end), (if .modmask % 8 >= 4 then "ctrl" else empty end),
     (if .modmask % 16 >= 8 then "alt" else empty end), (if .modmask % 2 == 1 then "shift" else empty end), .key] | join("+")')
