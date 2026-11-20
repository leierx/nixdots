export QS_TEST_MONITORS="DP-1:1920x1080:1"

summaries() { echo "(.history | map(.summary)) == $1"; }

qst case "an app keeps its newest three notifications once their popups go"
notify-send -a Mail "mail 1"
for n in 1 2 3 4; do notify-send -a Chat "chat $n"; done
qst wait "$(summaries '["chat 4", "chat 3", "chat 2", "chat 1", "mail 1"]')"
qst ipc notifications hidePopups
qst wait "$(summaries '["chat 4", "chat 3", "chat 2", "mail 1"]') and (.popups | length) == 0"

qst case "a sixth popup puts the oldest away, and with it its place in the history"
for n in 1 2 3 4 5 6; do notify-send -a Chat "chat $n"; done
qst wait "(.popups | map(.summary)) == [\"chat 6\", \"chat 5\", \"chat 4\", \"chat 3\", \"chat 2\"] and $(summaries '["chat 6", "chat 5", "chat 4", "chat 3", "chat 2"]')"

qst case "a stack tag replaces the earlier notification in place"
notify-send -a Volume -h string:x-dunst-stack-tag:volume "Volume 10"
notify-send -a Volume -h string:x-dunst-stack-tag:volume "Volume 20"
qst wait "$(summaries '["Volume 20"]') and (.popups | map(.summary)) == [\"Volume 20\"]"
qst stays "$(summaries '["Volume 20"]')"

qst case "under Do Not Disturb a transient notification never lands and a normal one stays in the history"
qst ipc notifications setDnd true
qst wait '.dnd'
notify-send -e -a Chat "gone"
notify-send -a Chat "kept"
qst wait "$(summaries '["kept"]') and (.popups | length) == 0"
qst stays "$(summaries '["kept"]') and (.popups | length) == 0"

qst case "under Do Not Disturb a critical notification still pops up"
qst ipc notifications setDnd true
qst wait '.dnd'
notify-send -u critical -a Battery "battery low"
qst wait '(.popups | map(.summary)) == ["battery low"]'

qst case "the bell counts notifications not yet looked at, and a click on it opens the center and checks them"
qst wait '.unchecked == 0'
notify-send -a Chat "one"
notify-send -a Mail "two"
qst wait '.unchecked == 2'
qst ipc notifications hidePopups
# The bell, last on the bar with no tray items.
qst pointer 1890 21
qst click left 1894 21
qst wait '.panel == "center" and .unchecked == 0 and .notifications == 2'

qst case "one arriving while the center is open is checked, one after it closes is not"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
notify-send -a Chat "seen"
qst wait '.notifications == 1'
qst stays '.unchecked == 0' 1
qst ipc panels close > /dev/null
qst wait '.panel == ""'
notify-send -a Chat "new"
qst wait '.unchecked == 1 and .notifications == 2'

qst case "hovering a popup holds those above it, which would move it away, but not those below"
notify-send -t 1500 -a Chat "bottom"
qst wait '(.popups | length) == 1'
notify-send -t 1500 -a Chat "middle"
notify-send -t 1500 -a Mail "top"
qst wait '(.popups | map(.summary)) == ["top", "middle", "bottom"]'
# The second card from the top of DP-1's stack.
qst pointer 1640 160
qst pointer 1642 162
qst wait '.popups[1].hovered'
qst wait '(.popups | map(.summary)) == ["top", "middle"]' 4
qst stays '(.popups | map(.summary)) == ["top", "middle"]' 2
qst pointer 900 600
qst wait '(.popups | length) == 0' 4

qst case "a popup put away under the pointer is no longer held"
notify-send -t 0 -a Chat "under the pointer"
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst pointer "$x" "$y"
qst pointer $((x + 2)) $((y + 2))
qst wait '.popups[0].hovered'
qst ipc notifications hidePopups
qst stays '(.popups | length) == 0' 1

qst case "a flood plays a sound at most every 300 ms, and an app saying the same again is one card"
start=$(date +%s%N)
for _ in $(seq 20); do notify-send -a Echo "same" "same body"; done
for n in $(seq 40); do notify-send -a Burst "burst $n" & done
wait
qst wait '(.history | map(select(.app == "Echo")) | length) == 1 and (.history | map(select(.app == "Burst")) | length) >= 3'
took=$((($(date +%s%N) - start) / 1000000))
sounds=$(qst actions | grep -c '^pw-play' || true)
[ "$sounds" -le $((took / 300 + 1)) ] || { echo "$sounds sounds in $took ms"; exit 1; }

qst case "a picture sent as a bare path, as notify-send -i /file sends it, draws as that file"
picture=$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg
notify-send -a Screenshot -n accessories-screenshot -i "$picture" "Screenshot saved"
qst wait "(.popups | length) == 1 and .history[0].image == \"file://$picture\""
