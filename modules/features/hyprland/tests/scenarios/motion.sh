export QS_TEST_MONITORS="DP-1:1920x1080:1"

# `qst motion stop` fails on anything that goes back and forth, or snaps while the rest of its window eases.
qst case "a center group eases open and shut without a jump"
# alone: a frame dropped on a loaded machine reads as a jump
notify-send -a Chat "first" "$(printf 'A body long enough to be cut short on its line. %.0s' 1 2 3)"
notify-send -a Chat "second" "another"
qst wait '.notifications == 2'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst stays '.panel == "center:DP-1"' 0.5
read -r x y _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst motion start
qst click left "$x" "$y"
qst stays '.panel == "center:DP-1"' 0.6
qst motion stop > /dev/null
qst motion start
qst click left "$x" "$y"
qst stays '.panel == "center:DP-1"' 0.6
qst motion stop > /dev/null

qst case "the OSD fades out over Shell's 100 ms, not in a moment"
# alone: it times the fade frame by frame
qst wait '.osdSettling == false'
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5
qst wait '.osd.kind == "volume"'
qst motion start
qst wait '.osd == null' 3
qst stays '.osd == null' 0.5
# An ease-out shows its last visible frame two thirds in; a jump would take one frame.
qst motion stop | jq -e 'any(.moved[]; .property == "opacity" and .from > .to and .end - .start >= 50)' > /dev/null

qst case "a toggle menu handed to its row's other, or to another row's, moves the card one way"
# alone: a frame dropped on a loaded machine reads as a jump
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70 > /dev/null
qst bluetooth add 11:22:33:44:55:02 Mouse input-mouse ok paired > /dev/null
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst click ControlsPanel:menu:vpn
qst wait '.controls.menu == "vpn"'
qst stays '.controls.menu == "vpn"' 0.5
for menu in bluetooth wifi night sound; do
  qst motion start
  qst click "ControlsPanel:menu:$menu"
  qst stays ".controls.menu == \"$menu\"" 0.6
  qst motion stop > /dev/null
done
