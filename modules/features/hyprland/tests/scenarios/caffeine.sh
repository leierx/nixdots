export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "Caffeine starts its unit, and stops it"
qst wait '.caffeine == false'
qst ipc caffeine toggle
qst wait '.caffeine'
qst actions | grep -qx 'systemctl --user start caffeine.service'
qst ipc caffeine toggle
qst wait '.caffeine == false'
qst actions | grep -qx 'systemctl --user stop caffeine.service'

qst case "a unit started elsewhere shows, and one that stops by itself goes"
systemctl --user start caffeine.service
qst wait '.caffeine' 7
systemctl --user stop caffeine.service
qst wait '.caffeine == false' 7

qst case "with the control centre open a change elsewhere shows sooner"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
systemctl --user start caffeine.service
qst wait '.caffeine' 3

qst case "it outlives a restart of the shell"
qst ipc caffeine set true
qst wait '.caffeine'
qst restart > /dev/null
qst wait '.caffeine'

qst case "the control centre's Caffeine pill, beside Night Light, turns it on and off, and the status button shows a cup while it is on"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst wait '([.controls.toggles[].key] | index("caffeine")) == ([.controls.toggles[].key] | index("night")) + 1'
read -r x y _ < <(qst areas ControlsPanel | awk -F'\t' 'index($3, "pill:caffeine") { print $1, $2; exit }')
qst click left "$x" "$y"
qst wait '.caffeine and (.status[0].glyphs | index("caffeine")) != null'
qst actions | grep -qx 'systemctl --user start caffeine.service'
qst click left "$x" "$y"
qst wait '(.caffeine | not) and (.status[0].glyphs | index("caffeine")) == null'
