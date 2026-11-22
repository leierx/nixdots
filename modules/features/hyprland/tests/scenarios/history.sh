export QS_TEST_MONITORS="DP-1:1920x1080:1"

# A notification whose picture only the server holds, as chat apps and players send them.
pixel() {
  gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "'$1'" "uint32 0" "''" "'$2'" "'a picture from memory'" "@as []" \
    "{'image-data': <(2, 2, 8, true, 8, 4, [byte 255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255])>}" "int32 -1" > /dev/null
}

images() { ls -A "$(qst state .historyImages | jq -r .)" 2> /dev/null || true; }

qst case "the history comes back after a restart, its pictures too, checked as it was"
notify-send -a Mail "older"
pixel Chat "with a picture"
qst wait '.notifications == 2 and any(.history[]; .summary == "with a picture" and (.kept | index("image")) != null)'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and .unchecked == 0'
qst ipc panels close > /dev/null
notify-send -a Mail "newest"
qst wait '.notifications == 3 and .unchecked == 1'
qst stays '.notifications == 3' 1
qst restart > /dev/null
qst wait '(.history | map(.summary)) == ["newest", "with a picture", "older"] and all(.history[]; .restored) and .unchecked == 1 and (.popups | length) == 0'
# The census checks the saved picture loads while the center shows it.
qst ipc panels open center > /dev/null
qst stays '.panel == "center"' 1

qst case "a reload in place keeps the live notifications' ages, and what was seen stays seen"
notify-send -a Mail "one"
notify-send -a Chat "two"
qst wait '.notifications == 2'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and .unchecked == 0'
qst ipc panels close > /dev/null
before=$(qst state '.history | map(.time)')
qst stays '.notifications == 2' 1
# A change to a file of the shell reloads it in place, which hands the live notifications over.
loaded=$(grep -ac 'Configuration Loaded' "$QS_TEST_DIR/qs.log")
echo >> "$QS_TEST_DIR/shell/shell.qml"
for _ in $(seq 100); do [ "$(grep -ac 'Configuration Loaded' "$QS_TEST_DIR/qs.log")" -gt "$loaded" ] && qst state .notifications > /dev/null 2>&1 && break; sleep 0.1; done # sleep: the probe goes with the reload, and qs takes no queries for a while after
qst wait '.notifications == 2 and .unchecked == 0 and (.history | map(.restored)) == [false, false]'
qst wait "(.history | map(.time)) == $before"

qst case "a cleared history leaves no saved pictures behind"
pixel Chat "with a picture"
qst wait 'any(.history[]; (.kept | index("image")) != null)'
qst stays '.notifications == 1' 1
[ -n "$(images)" ] || { echo "no picture was saved"; exit 1; }
qst ipc notifications clear
qst wait '.notifications == 0'
qst stays '.notifications == 0' 1
[ -z "$(images)" ] || { echo "pictures left behind: $(images)"; exit 1; }

qst case "a damaged history file starts the shell empty, with one warning"
file=$(qst state .historyFile | jq -r .)
printf '{"version": 1, "notifications": [' > "$file"
qst restart > /dev/null
qst expect 'notification-history.json: unreadable'
qst stays '.notifications == 0' 1
printf '%s' '{"version": 1, "notifications": [{"uid": "../x"}, 3, null]}' > "$file"
qst restart > /dev/null
qst stays '.notifications == 0' 1
notify-send -a Chat "after"
qst wait '.notifications == 1'

qst case "a transient notification is never saved"
notify-send -e -a Chat "gone"
notify-send -a Chat "kept"
qst wait '.notifications == 2'
qst stays '.notifications == 2' 1
qst restart > /dev/null
qst wait '(.history | map(.summary)) == ["kept"]'
