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
qst wait '.panel == "center:DP-1" and .unchecked == 0 and .notifications == 2 and (.status[0].glyphs | index("bell") | not)'

qst case "one arriving while the center is open is checked, one after it closes is not"
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
notify-send -a Chat "seen"
qst wait '.notifications == 1'
qst stays '.unchecked == 0' 1
qst ipc panels close > /dev/null
qst wait '.panel == ""'
notify-send -a Chat "new"
qst wait '.unchecked == 1 and .notifications == 2'

qst case "a popup under the pointer holds while it is read and times out once the pointer leaves, and the others time out as any other"
notify-send -t 1500 -a Chat "bottom"
qst wait '(.popups | length) == 1'
notify-send -t 1500 -a Chat "middle"
notify-send -t 1500 -a Mail "top"
qst wait '(.popups | map(.summary)) == ["top", "middle", "bottom"]'
# The second card from the top of DP-1's stack.
qst pointer 1640 160
qst pointer 1642 162
qst wait '(.popups | map(.summary)) == ["middle"]' 4
qst stays '(.popups | map(.summary)) == ["middle"]' 1
qst pointer 900 600
qst wait '(.popups | length) == 0' 4

qst case "an update by id closed in the same breath stays closed, and the bell does not stick"
qst flood 0 --app Chat --updates 1 --close > /dev/null
qst stays '.notifications == 0 and .unchecked == 0 and (.status[0].glyphs | index("bell") | not)' 2

qst case "updates by id past the flood limit only update their card"
qst flood 0 --app Chat --updates 300 > /dev/null
qst wait '.notifications == 1 and (.popups | length) == 1'
qst stays '.notifications == 1 and (.popups | length) == 1' 1

qst case "markup an app sends is never drawn: a bare ampersand, an unknown entity, an image in an action's label"
notify-send -a Chat "Q&A" 'a&b; c'
notify-send -a Mail -A 'x=<img src="file:///nope">' -A 'y=<font size="72">big</font>' "labels" > /dev/null &
qst wait '(.popups | length) == 2'
qst stays '(.popups | length) == 2' 0.5
qst ipc notifications clear > /dev/null
wait

qst case "a flood plays a sound at most every 300 ms, and an app saying the same again is one card"
start=$(date +%s%N)
for _ in $(seq 20); do notify-send -a Echo "same" "same body"; done
for n in $(seq 40); do notify-send -a Burst "burst $n" & done
wait
qst wait '(.history | map(select(.app == "Echo")) | length) == 1 and (.history | map(select(.app == "Burst")) | length) >= 3'
took=$((($(date +%s%N) - start) / 1000000))
sounds=$(qst actions | grep -c '^pw-play' || true)
[ "$sounds" -le $((took / 300 + 1)) ] || { echo "$sounds sounds in $took ms"; exit 1; }

qst case "a picture sent as a bare path, as notify-send -i /file sends it, draws as its copy in the cache"
picture=$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg
notify-send -a Screenshot -n accessories-screenshot -i "$picture" "Screenshot Saved"
qst wait '.historyImages as $dir | .history[0].image as $image | (.popups | length) == 1 and ($image | startswith("file://" + $dir + "/")) and (.notificationPictures | index($image)) != null'
copy=$(qst state '.history[0].image' | jq -r 'ltrimstr("file://")')
cmp "$copy" "$picture"

qst case "a picture or an app icon that is a pipe never holds the shell"
fifo=$QS_TEST_DIR/picture.fifo
rm -f "$fifo" && mkfifo "$fifo"
notify-send -a Bare -i "$fifo" "a pipe as a bare path"
notify-send -a Url -h "string:image-path:file://$fifo" "a pipe as a file URL"
qst flood 1 --app Icon --icon "$fifo" > /dev/null
qst wait '.notifications == 3 and (.popups | length) == 3 and all(.history[]; .image == null)'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst stays '.panel == "center:DP-1" and all(.notificationPictures[]; contains(".fifo") | not)' 1

qst case "a picture and a sound whose paths hold a space, a # and a % draw and play"
dir=$(mktemp -d -p "$QS_TEST_DIR")
cp "$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg" "$dir/Shot #2 %41.svg"
cp "$QS_TEST_REPO/modules/features/hyprland/quickshell/notifications/sounds/notification.oga" "$dir/a b%.oga"
url() { jq -rn --arg path "$1" '"file://" + ($path | split("/") | map(@uri) | join("/"))'; }
notify-send -a Sound -h "string:sound-file:$(url "$dir/a b%.oga")" "a sound"
notify-send -a Bare -i "$dir/Shot #2 %41.svg" "a bare path"
notify-send -a Url -h "string:image-path:$(url "$dir/Shot #2 %41.svg")" "a file URL"
qst wait '.notificationPictures as $drawn | [.history[].image | select(. != null)] as $images | .notifications == 3 and ($images | length) == 2 and all($images[]; . as $image | $drawn | index($image) != null)'
played() { qst actions | grep -qxF "pw-play $dir/a b%.oga"; }
for _ in $(seq 20); do played && break; qst stays true 0.05; done
played || { qst actions | grep pw-play; echo "the sound was not played from its path"; exit 1; }

qst case "an app icon naming another notification's picture in memory draws nothing of it, nor keeps it"
send() {
  gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "'$1'" "uint32 0" "'$2'" "'$1'" "'a body'" "@as []" "$3" "int32 -1" > /dev/null
}
send Chat '' "{'image-data': <(2, 2, 8, true, 8, 4, [byte 255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255])>}"
qst wait '.notifications == 1 and (.history[0].image | startswith("image://qsimage/"))'
victim=$(qst state '.history[0].image' | jq -r .)
send Spoof "$victim" '@a{sv} {}'
qst wait '.notifications == 2 and (.popups | length) == 2'
qst stays "(.notificationPictures | map(select(. == \"$victim\")) | length) == 1 and .history[0].kept == []" 1

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

qst case "a right click dismisses a popup, and a center card, never opening it or closing the center"
notify-send -t 0 -a Chat "gone"
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst click right "$x" "$y"
qst wait '(.popups | length) == 0 and .notifications == 0'
notify-send -a Chat "first"
notify-send -a Mail "second"
qst wait '.notifications == 2'
qst ipc notifications hidePopups > /dev/null
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1" and (.center | length) == 2'
read -r x y _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst click right "$x" "$y"
qst wait '.notifications == 1'
qst stays '.notifications == 1 and .panel == "center:DP-1"' 0.6

qst case "the center's close buttons show without the pointer: a lone card's, a group's, and each card's once it expands, each closing its own"
notify-send -a Chat "alone"
notify-send -a Mail "one"
notify-send -a Mail "two"
qst wait '.notifications == 3'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
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
qst wait '.panel == "center:DP-1" and (.center | length) == 16'
qst click NotificationCenter:action:Clear
qst wait '.notifications == 0 and (.center | length) == 0' 2
qst stays '.panel == "center:DP-1" and .notifications == 0' 1
areas=$(qst areas 'NotificationCenter')
grep -q 'switch:dnd' <<< "$areas" && ! grep -q 'action:Undo' <<< "$areas" || { echo "$areas"; echo "the center is gone, or Clear still offers Undo"; exit 1; }

qst case "Clear while stack-tagged notifications replace themselves mid-slide: every card ends in place or gone"
tagged() { for n in 1 2 3 4; do notify-send -a "Level $n" -h "string:x-dunst-stack-tag:level$n" "level $n" "$1" & done; wait; }
tagged first
qst wait '.notifications == 4'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1" and (.center | length) == 4'
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
qst wait '.panel == "center:DP-1" and (.center | length) == 1'
read -r cx cy _ < <(qst areas 'NotificationCenter/SwipeArea' | head -1)
qst click left "$cx" "$cy"
qst wait '.center[0].expanded'
qst click NotificationCenter:action:More
qst wait '.centerMore == 1'
qst click 'NotificationCenter:action:Collapse All'
qst wait '.center[0].expanded == false and .centerMore == 0'
qst click left "$cx" "$cy"
qst wait '.center[0].expanded'
qst stays '.centerMore == 0' 0.5

qst case "the keyboard reaches the center's cards: Return expands a group, Delete dismisses what it is on"
notify-send -a Chat "alone"
notify-send -a Mail "one"
notify-send -a Mail "two"
qst wait '.notifications == 3'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
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
qst wait '.panel == "center:DP-1"'
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
qst wait '.panel == "center:DP-1"'
read -r media _ < <(qst areas NotificationCenter | awk -F'\t' 'index($3, "media:play") { print $2; exit }')
read -r first _ < <(qst areas NotificationCenter | awk -F'\t' '$3 ~ /SwipeArea|NotificationGroup/ { print $2; exit }')
[ -n "$media" ] && [ -n "$first" ] && [ "$media" -lt "$first" ] || { echo "the player is not above the notifications ($media, $first)"; exit 1; }

qst case "hints no honest client sends: pictures bigger than their bytes, endless and negative timeouts, three hundred actions, an id nobody issued, a pipe and a device as sounds"
notify() {
  gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "'$2'" "uint32 $1" "''" "'$2'" "'a body'" "$3" "$4" "int32 $5" > /dev/null
}
bytes="[byte 255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255]"
fifo=$QS_TEST_DIR/sound.fifo
rm -f "$fifo" && mkfifo "$fifo"
# Quickshell's own, as it drops the two pictures it cannot draw.
qst expect 'Unable to parse pixmap as it holds 16 bytes, too few for 100 x 100'
qst expect 'Unable to parse pixmap as it holds 16 bytes, too few for 65535 x 65535'
actions=$(for n in $(seq 300); do printf "'a%d', 'Action %d', " "$n" "$n"; done)
notify 0 "a picture larger than its bytes" "@as []" "{'image-data': <(100, 100, 400, true, 8, 4, $bytes)>}" -1
notify 0 "a picture of 65535 squared" "@as []" "{'image-data': <(65535, 65535, 262140, true, 8, 4, $bytes)>}" -1
notify 0 "a timeout that never ends" "@as []" "@a{sv} {}" 2147483647
notify 0 "a timeout below nothing" "@as []" "@a{sv} {}" -5
notify 0 "three hundred actions" "[${actions%, }]" "@a{sv} {}" -1
notify 4242 "an id nobody issued" "@as []" "@a{sv} {}" -1
notify 0 "a pipe to play" "@as []" "{'sound-file': <'$fifo'>}" -1
notify 0 "a device to play" "@as []" "{'sound-file': <'/dev/zero'>}" -1
qst wait '.notifications == 8 and (.popups | length) == 5' 10
qst actions | grep -E '^pw-play (/dev/zero|.*sound\.fifo)' && { echo "a pipe or a device was played"; exit 1; }
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst stays '.panel == "center:DP-1" and .notifications == 8' 1
