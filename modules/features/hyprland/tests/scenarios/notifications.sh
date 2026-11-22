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

qst case "the status button rings the bell for notifications not yet looked at, and the center from the clock checks them"
qst wait '.unchecked == 0 and (.status[0].glyphs | index("bell") | not)'
notify-send -a Chat "one"
notify-send -a Mail "two"
qst wait '.unchecked == 2 and .status[0].glyphs[0] == "bell"'
qst ipc notifications hidePopups
# The clock, in the middle of the bar.
qst click left 960 17
qst wait '.panel == "center" and .unchecked == 0 and .notifications == 2 and (.status[0].glyphs | index("bell") | not)'

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

qst case "a popup under the pointer times out as any other, and those above it too"
notify-send -t 1500 -a Chat "bottom"
qst wait '(.popups | length) == 1'
notify-send -t 1500 -a Chat "middle"
notify-send -t 1500 -a Mail "top"
qst wait '(.popups | map(.summary)) == ["top", "middle", "bottom"]'
# The second card from the top of DP-1's stack.
qst pointer 1640 160
qst pointer 1642 162
qst wait '(.popups | length) == 0' 4

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
notify-send -a Screenshot -n accessories-screenshot -i "$picture" "Screenshot Saved"
qst wait "(.popups | length) == 1 and .history[0].image == \"file://$picture\""

qst case "a burst created in one millisecond names each notification's saved pictures apart"
qst flood 30 --apps 30 &
qst flood 30 --apps 30 --app Urgent --urgency 2 &
wait
qst wait '.notifications == 60'
qst stays '(.history | map(.uid) | unique | length) == 60' 0.5

qst case "a group leads with its critical notification however old, and keeps the rest newest first"
notify-send -a Mail -u critical "disk almost full"
notify-send -a Mail "second"
notify-send -a Mail "third"
qst wait '.notifications == 3'
qst ipc panels open center > /dev/null
qst wait '(.center | map(select(.app == "Mail")) | .[0].lines | map(.summary)) == ["disk almost full", "third", "second"]'

qst case "a right click on a popup or a center card leaves it be"
notify-send -t 0 -a Chat "stays"
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst click right "$x" "$y"
qst stays '(.popups | length) == 1' 0.6
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
read -r x y _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst click right "$x" "$y"
qst stays '.notifications == 1 and .panel == "center"' 0.6

qst case "the center's close buttons show without the pointer: a lone card's, a group's, and each card's once it expands, each closing its own"
notify-send -a Chat "alone"
notify-send -a Mail "one"
notify-send -a Mail "two"
qst wait '.notifications == 3'
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
qst pointer 1800 900
closes() { qst areas 'NotificationCenter' | awk -F'\t' 'index($3, ":close") { print $1, $2 }' | sort -n -k2; }
for _ in $(seq 20); do [ "$(closes | wc -l)" -eq 2 ] && break; sleep 0.1; done # sleep: the areas come from the window walk, outside the probe
[ "$(closes | wc -l)" -eq 2 ] || { closes; echo "not two close buttons"; exit 1; }
# Mail is newest, so its group comes first; expanded, each of its two cards has one.
read -r x y _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst click left "$x" "$y"
qst wait '.center | map(select(.app == "Mail"))[0].expanded'
for _ in $(seq 20); do [ "$(closes | wc -l)" -eq 3 ] && break; sleep 0.1; done # sleep: as above
read -r x y < <(closes | head -1)
qst click left "$x" "$y"
qst wait '.notifications == 2 and (.history | map(.summary) | index("two") | not)'

qst case "Clear dismisses every group at once, those scrolled out of view too, with nothing to undo"
for n in $(seq 16); do notify-send -a "App $n" "message $n" "a body long enough to take a line of its own"; done
qst wait '.notifications == 16'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and (.center | length) == 16'
qst click NotificationCenter:action:Clear
qst wait '.notifications == 0 and (.center | length) == 0' 2
qst stays '.panel == "center" and .notifications == 0' 1
! qst areas 'NotificationCenter' | grep -q 'action:Undo' || { echo "Clear still offers Undo"; exit 1; }

qst case "Clear while stack-tagged notifications replace themselves mid-slide: every card ends in place or gone"
tagged() { for n in 1 2 3 4; do notify-send -a "Level $n" -h "string:x-dunst-stack-tag:level$n" "level $n" "$1" & done; wait; }
tagged first
qst wait '.notifications == 4'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and (.center | length) == 4'
for round in 1 2 3 4 5; do
  qst click NotificationCenter:action:Clear
  tagged "round $round"
  qst wait '.notifications == 4 and (.center | length) == 4 and (.center | map(select(.slid != 0)) | length) == 0'
done

qst case "a group keeps its place in the open center as its newest goes, a new app comes in on top, and the next open sorts them"
order() { echo "(.center | sort_by(.y) | map(.app)) == $1"; }
notify-send -a Bravo "bravo old"
notify-send -a Alpha "alpha"
newest=$(notify-send -p -a Bravo "bravo new")
notify-send -a Charlie "charlie"
qst wait '.notifications == 4'
qst ipc panels open center > /dev/null
qst wait "$(order '["Charlie", "Bravo", "Alpha"]')"
busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications CloseNotification u "$newest" > /dev/null
qst wait ".notifications == 3 and $(order '["Charlie", "Bravo", "Alpha"]')"
qst stays "$(order '["Charlie", "Bravo", "Alpha"]')" 0.5
notify-send -a Delta "delta"
qst wait "$(order '["Delta", "Charlie", "Bravo", "Alpha"]')"
qst ipc panels close > /dev/null
qst wait '.panel == ""'
qst ipc panels open center > /dev/null
qst wait "$(order '["Delta", "Charlie", "Alpha", "Bravo"]')"

qst case "Collapse All shuts a card's More along with its group, so it opens again with two actions"
notify-send -a Mail -A one=One -A two=Two -A three=Three -A four=Four "pick one" > /dev/null &
qst wait '.notifications == 1'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and (.center | length) == 1'
read -r cx cy _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst click left "$cx" "$cy"
qst wait '.center[0].expanded'
qst click NotificationCenter:action:More
qst wait '.centerMore == 1'
qst click 'NotificationCenter:action:Collapse All'
qst wait '(.center[0].expanded | not) and .centerMore == 0'
qst click left "$cx" "$cy"
qst wait '.center[0].expanded'
qst stays '.centerMore == 0' 0.5

qst case "the keyboard reaches the center's cards: Return expands a group, Delete dismisses what it is on"
notify-send -a Chat "alone"
notify-send -a Mail "one"
notify-send -a Mail "two"
qst wait '.notifications == 3'
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
qst key Tab
qst wait '.focused != null and .ring'
for _ in $(seq 6); do
  [ "$(qst state '.focused')" = '"NotificationCenter/NotificationGroup"' ] && break
  qst key Tab
done
qst wait '.focused == "NotificationCenter/NotificationGroup"'
qst key Return
# Mail is newest, so its group comes first.
qst wait '.center | map(select(.app == "Mail"))[0].expanded'
qst key Delete
qst wait '.notifications == 1 and .history[0].app == "Chat"'

qst case "Do Not Disturb is a switch in the center's footer, as GNOME's, and the bar strikes the bell while it is on"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
read -r x y _ < <(qst areas NotificationCenter | awk -F'\t' 'index($3, "switch:dnd") { print $1, $2; exit }')
[ -n "$x" ] || { echo "no Do Not Disturb switch in the center"; exit 1; }
qst click left "$x" "$y"
qst wait '.dnd and (.status[0].glyphs | index("dnd")) != null'
qst click left "$x" "$y"
qst wait '(.dnd | not)'
# The keyboard reaches it too: Tab from the card lands on it first.
qst key Tab space
qst wait '.dnd'

qst case "the player that played last heads the center's list, above the notifications"
qst player add spotify Spotify Playing
notify-send -a Chat "Lunch at noon" "Meet at the usual place"
qst wait '.notifications == 1 and .controls.media.identity == "Spotify"'
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
read -r media _ < <(qst areas NotificationCenter | awk -F'\t' 'index($3, "media:play") { print $2; exit }')
read -r first _ < <(qst areas NotificationCenter | awk -F'\t' '$3 ~ /SwipeArea|NotificationGroup/ { print $2; exit }')
[ -n "$media" ] && [ -n "$first" ] && [ "$media" -lt "$first" ] || { echo "the player is not above the notifications ($media, $first)"; exit 1; }
