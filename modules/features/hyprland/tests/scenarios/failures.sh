export QS_TEST_MONITORS="DP-1:1920x1080:1"

# What the shell runs failing as it can: the shell stays up, says so where someone waits on it, and its panel still opens and closes.
reopens() {
  qst ipc panels open "$1" > /dev/null
  qst wait "(.panel | startswith(\"$1\"))"
  qst ipc panels close > /dev/null
  qst wait '.panel == ""'
}

notified() { qst wait "any(.history[]; .summary == \"$1\")"; }

qst case "a clipboard whose cliphist fails, or is not installed, says so"
qst fail cliphist exit
qst ipc panels open clipboard > /dev/null
qst wait '.notifications == 1 and .history[0].summary == "cliphist list" and .panel == ""'
qst fail cliphist missing
qst ipc panels open clipboard > /dev/null
qst wait '.notifications == 2 and .history[0].summary == "cliphist list" and .panel == ""'
qst fail cliphist off
reopens clipboard

qst case "a command started again from its own exit, of a program not installed, says so"
qst expect 'Process failed to start.*qst-missing'
qst ipc probe chain true qst-missing > /dev/null
qst wait '.notifications == 1 and .history[0].summary == "qst-missing"'

qst case "monitor layouts outlive hyprmoncfg failing and writing garbage"
qst fail hyprmoncfg exit
qst expect 'hyprmoncfg status --json: hyprmoncfg: failed for qst'
reopens monitors
qst fail hyprmoncfg garbage
qst expect 'hyprmoncfg status: SyntaxError'
reopens monitors

qst case "the shortcuts window says when hyprctl fails"
qst fail hyprctl exit
qst ipc panels open shortcuts > /dev/null
notified "hyprctl binds -j"
qst wait '.panel == ""'

qst case "the camera watcher crashing is started again, and the weather waits when curl fails"
qst fail camera-users crash
qst fail curl exit
qst restart > /dev/null
qst expect 'camera-users stopped, starting it again'
# The forecast fetched at the start is cached, so the restart may not ask again.
qst expect --may 'Weather: fetching the forecast'
qst stays '.privacy.camera == null' 1
reopens center

qst case "the forecast is kept: a restart asks MET nothing before it expires, and with curl failing the last one shows"
qst wait '.weather.hours > 0 and .weather.now == "clearsky_day"' 10
[ "$(qst actions | grep -c 'api.met.no')" = 1 ] || { qst actions; echo "the forecast was not fetched once"; exit 1; }
qst fail curl exit
qst restart > /dev/null
qst wait '.weather.hours > 0' 10
qst actions | grep -q 'api.met.no.*(failing)' && { qst actions; echo "a restart asked MET again before the forecast expired"; exit 1; }
true

qst case "a hyprctl that never answers: the shortcuts give up and say so, and come back with it"
qst fail hyprctl hang 'binds*'
qst ipc panels open shortcuts > /dev/null
qst wait '.panel == "shortcuts"'
qst wait 'any(.history[]; .summary == "hyprctl binds -j") and .panel == ""' 10
qst fail hyprctl off
reopens shortcuts

qst case "the shortcuts with no binds to show say so rather than open on nothing"
qst fail hyprctl 'say=[]' 'binds*'
qst ipc panels open shortcuts > /dev/null
notified "hyprctl binds -j"
qst wait '.panel == ""'

qst case "a cliphist that never answers closes the clipboard saying so, and the next open lists"
echo "a clip" | cliphist store
qst fail cliphist hang list
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard"'
qst wait 'any(.history[]; .summary == "cliphist list") and .panel == ""' 15
qst fail cliphist off
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard" and (.results | index("a clip")) != null'

qst case "a cliphist with no history yet is an empty clipboard, not a failure"
rm -f "$QS_TEST_DIR/clip.db"
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard" and .results == []'
qst stays '.panel == "clipboard" and .notifications == 0' 1

qst case "wpctl never answering: the input picked through it says so, and the next pick lands"
qst fail wpctl hang 'set-default*'
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.menu == "sound"'
# A virtual input is set through wpctl; Quickshell takes only plain ones.
qst click "ControlsPanel:Noise Cancelling"
qst wait 'any(.history[]; .summary == "Input")' 15
qst fail wpctl off
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.menu == "sound"'
qst click "ControlsPanel:Noise Cancelling"
qst wait '.microphone.input == "Noise Cancelling"' 10

qst case "systemctl never answering: Caffeine says so and shows what the unit is, and turns on once it answers"
qst fail systemctl hang '*start*'
qst ipc caffeine toggle
qst wait 'any(.history[]; .summary == "Caffeine") and .caffeine == false' 15
qst fail systemctl off
qst ipc caffeine toggle
qst wait '.caffeine'
qst x sh -c '[ -e "${XDG_CONFIG_HOME%/cfg}/units/caffeine.service" ]'

qst case "tools that answer slowly, cut short, at enormous length or exit failing after a good answer keep every panel opening"
for mode in slow truncated huge lie; do
  qst fail hyprmoncfg "$mode"
  qst fail cliphist "$mode" list
  qst fail hyprctl "$mode" 'binds*'
  for panel in monitors clipboard shortcuts; do
    qst ipc panels open "$panel" > /dev/null
    qst wait "(.panel == \"$panel\") or any(.history[]; .app == \"Shell\")" 10
    qst ipc panels close > /dev/null
    qst wait '.panel == ""'
  done
  qst ipc notifications clear > /dev/null
done
qst expect --may 'hyprmoncfg status --json: '
qst expect --may 'hyprmoncfg status: SyntaxError'

qst case "the shell crashing comes back whole: its history, its panels, its notifications, and the helpers the crashed one left go at their next event"
notify-send -a Mail "before the crash"
qst wait '.notifications == 1'
# Quickshell starts a crashed shell again only once it has run ten seconds.
qst stays '.notifications == 1' 10.5
qst expect 'Quickshell has crashed under pid'
qst expect --may 'Further crash information is stored'
qst expect --may 'Quickshell has been restarted'
# The crashed shell's bus names go a moment after it: its notification server and tray watcher come back once they do.
qst expect --may 'Could not register notification server|Registration will be attempted again'
qst expect --may 'Error reading "RegisteredStatusNotifierItems"|Message recipient disconnected from message bus without replying'
qst kill SEGV
qst wait '(.history | map(.summary)) == ["before the crash"]' 10
reopens center
reopens apps
notify-send -a Mail "after the crash"
qst wait '.notifications == 2' 10
# The relaunch is an exec in place, so what the crashed shell ran is still its child, writing to nobody until it tries.
qst camera open zoom
qst backlight intel_backlight 40
qst network cable enp8s0 off
qst wait '.privacy.camera == ["zoom"] and (.controls.network.wired | map(select(.name == "enp8s0"))[0].link | not)'

qst case "the shell killed outright as it saves comes back with its history whole"
for n in $(seq 20); do notify-send -a "App $n" "note $n"; done
qst kill KILL
qst restart > /dev/null
qst wait '.historyLoaded'
file=$(qst state .historyFile | jq -r .)
[ ! -e "$file" ] || jq -e '.notifications | type == "array"' "$file" > /dev/null || { echo "the history was left unreadable"; exit 1; }

qst case "state and cache that cannot be written cost a warning, not the shell, and are written again once they can be"
state=$(dirname "$(qst state .historyFile | jq -r .)")
cache=$(qst state .cache | jq -r .)
mkdir -p "$state" "$cache"
chmod -R a-w "$state" "$cache"
# The shell's own warning, and Quickshell's beside it.
qst expect 'Writing .* failed'
qst expect 'Write of .* failed'
qst expect --may 'Pruning saved notification pictures: '
qst ipc notifications setDnd true
for n in $(seq 200); do notify-send -a "App $((n % 7))" "note $n"; done
qst wait '.dnd and .notifications >= 20' 15
echo "a clip to pick" | cliphist store
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard"'
qst key Return
qst wait 'any(.history[]; .summary == "Copying the clip")' 10
warnings=$(grep -acE '(Writing|Write of) .* failed' "$QS_TEST_DIR/qs.log")
[ "$warnings" -le 60 ] || { echo "$warnings warnings for one locked directory"; exit 1; }
chmod -R u+w "$state" "$cache"
notify-send -a Late "once it can"
for _ in $(seq 40); do [ -s "$state/notification-history.json" ] && jq -e 'any(.notifications[]; .summary == "once it can")' "$state/notification-history.json" > /dev/null && break; qst stays true 0.1; done
jq -e 'any(.notifications[]; .summary == "once it can")' "$state/notification-history.json" > /dev/null

QS_TEST_DISK=256k qst case "a full disk costs a warning, not the shell or a saved file: the history stays whole, and is written again once there is room"
qst expect 'Writing .*notification-history\.json failed'
qst expect --may 'Writing .* failed'
qst expect --may 'Write of .* failed'
qst expect --may 'Pruning saved notification pictures: '
file=$(qst state .historyFile | jq -r .)
for n in $(seq 5); do notify-send -a "App $n" "before $n"; done
qst wait '.historySaved == 5'
qst disk fill
qst disk sh -c '[ "$(df --output=avail "$1" | tail -1)" -eq 0 ]' sh "$(dirname "$file")" || { qst disk df "$(dirname "$file")"; echo "the disk is not full"; exit 1; }
notify-send -a Late "while full" "$(printf 'A body long enough to need a block of its own. %.0s' $(seq 100))"
qst wait '.historySaved == null and .notifications == 6'
qst disk jq -e '.notifications | length == 5' "$file" > /dev/null || { echo "the history on disk is not the last whole one"; exit 1; }
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst disk free
notify-send -a Late "with room again"
qst wait '.historySaved == 7'
qst disk sh -c 'for _ in $(seq 100); do jq -e ".notifications | length == 7" "$1" > /dev/null 2>&1 && exit 0; sleep 0.05; done; exit 1' sh "$file" || { echo "the history was not written again"; exit 1; } # sleep: the file is written off the shell's thread, after its own record of it changed
