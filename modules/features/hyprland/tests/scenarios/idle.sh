export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# hypridle drives the dim through `qs ipc call idle`, and its lock command holds it; these call it as they do.
shown() { echo "(.layers | map(select(endswith(\" quickshell:idle\"))) | length) == $1"; }
dims() { jq -e "any(.moved[]; .label | startswith(\"Idle/\")) and all(.moved[] | select(.label | startswith(\"Idle/\")); .property == \"opacity\" and $1)" > /dev/null; }

qst case "the dim darkens every screen steadily to its depth and stays there"
# alone: a frame dropped on a loaded machine reads as a jump
qst motion start
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"
qst stays "$(shown 2)" 1.5
qst motion stop | dims '(.to - 0.4 | fabs) < 0.01 and .end - .start >= 600'

qst case "the dim takes no input: the bar under it still opens the center"
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"
read -r x y _ < <(qst areas 'BarWindow/QQuickMouseArea' | awk -F '\t' '$1 == 960')
qst click left "$x" "$y"
qst wait '.panel == "center"'

qst case "cancel brings the screens back at once, and a dim can start again"
qst ipc idle fade 10 0.4
qst wait "$(shown 2)"
qst ipc idle cancel
qst wait "$(shown 0)"
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"

qst case "the lock command's hold reports the dim and keeps it still through a cancel"
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"
qst stays true 1.2
[ "$(qst ipc idle hold)" = 0.4 ]
qst ipc idle cancel
qst stays "$(shown 2)" 1
qst ipc idle locked
qst wait "$(shown 0)"

qst case "a hold mid-dim stops it where it is"
# alone: it reads the dim frame by frame and where a 4 s fade is after 1 s
qst ipc idle fade 4 0.4
qst wait "$(shown 2)"
qst stays true 1
dark=$(qst ipc idle hold)
awk -v d="$dark" 'BEGIN { exit !(d > 0 && d < 0.4) }'
qst motion start
qst stays "$(shown 2)" 1
qst motion stop | jq -e 'all(.moved[]; .label | startswith("Idle/") | not)' > /dev/null
qst ipc idle unlocked
qst wait "$(shown 0)"

qst case "nothing dims while locked, and unlocking lets it again"
qst ipc idle locked
qst ipc idle fade 1 0.4
qst stays "$(shown 0)" 1
qst ipc idle unlocked
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"

qst case "an unlock clears a hold that never got the lock"
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"
qst ipc idle hold > /dev/null
qst ipc idle unlocked
qst wait "$(shown 0)"
qst ipc idle fade 1 0.4
qst wait "$(shown 2)"
