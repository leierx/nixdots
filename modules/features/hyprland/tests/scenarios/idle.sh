export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# hypridle drives the fade through `qs ipc call idle`; these call it as its listener does.
shown() { echo "(.layers | map(select(endswith(\" quickshell:idle\"))) | length) == $1"; }

qst case "the fade darkens every screen steadily and stays black"
qst motion start
qst ipc idle fade 1
qst wait "$(shown 2)"
qst stays "$(shown 2)" 1.5
qst motion stop | jq -e 'any(.moved[]; .label | startswith("Idle/")) and all(.moved[] | select(.label | startswith("Idle/")); .property == "opacity" and .to > 0.99 and .end - .start >= 600)' > /dev/null

qst case "the fade takes no input: the bar under it still opens the center"
qst ipc idle fade 1
qst wait "$(shown 2)"
read -r x y _ < <(qst areas 'BarWindow/QQuickMouseArea' | awk -F '\t' '$1 == 960')
qst click left "$x" "$y"
qst wait '.panel == "center"'

qst case "cancel brings the screens back at once, and a fade can start again"
qst ipc idle fade 10
qst wait "$(shown 2)"
qst ipc idle cancel
qst wait "$(shown 0)"
qst ipc idle fade 1
qst wait "$(shown 2)"
