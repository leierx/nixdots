export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "keys typed as the launcher opens all land, on a shell just started"
# alone: keys race the launcher opening, and a loaded machine moves the race
qst key super+d
qst type firefox
qst wait '.field == "firefox"'

qst case "the launcher opens within a second of its key"
# alone: it times the open against the clock
start=$(date +%s%N)
qst key super+d
qst wait '.panel == "apps" and (.layers | index("DP-1 quickshell:launcher")) != null'
took=$((($(date +%s%N) - start) / 1000000))
[ "$took" -lt 1000 ] || { echo "the launcher took $took ms to open"; exit 1; }

qst case "a click on a window on another monitor closes the launcher and gives it the keyboard"
# alone: keys race the launcher opening, and a loaded machine moves the race
# Qt, when the launcher closes while its list is still building rows.
qst expect --may 'DelegateModel::cancel: index out range'
export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"
qst reset > /dev/null
qst focus DP-2
qst key super+Return
qst wait '(.windows | length) == 1' 10
qst focus DP-1
qst key super+d
qst type fire
qst wait '.panel == "apps" and .field == "fire"'
qst click left 2900 600
qst wait '.panel == ""'
[ "$(hyprctl activewindow -j | jq -r .monitor)" = 1 ] || { echo "the window on DP-2 did not get the keyboard"; exit 1; }

qst case "a click on another monitor's bare desktop closes the launcher, as one beside its card does"
export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"
qst reset > /dev/null
qst focus DP-1
qst key super+d
qst wait '.panel == "apps"'
qst click left 2900 600
qst wait '.panel == ""'

qst case "a word with one letter wrong, missing, extra or swapped still finds the app, below what matches as typed"
qst key super+d
qst wait '.panel == "apps"'
for typo in firfeox firefx fierfox fireffox; do
  qst key ctrl+a BackSpace
  qst type "$typo"
  qst wait ".field == \"$typo\" and (.results | index(\"Firefox\")) != null"
done
qst key ctrl+a BackSpace
qst type fire
qst wait '.field == "fire" and .results[0] == "Firefox"'

qst case "nixpkgs searches the package list by name first, a narrower query within the last, and Return runs the best match"
export QS_TEST_MONITORS="DP-1:1920x1080:1"
qst reset > /dev/null
qst key super+n
qst wait '.panel == "nixpkgs" and (.results | length) == 0'
qst type fire
qst wait '(.results | sort) == ["firefox", "firefox-esr", "firejail"] and .results[0] == "firefox"' 10
qst type f
qst wait '.results == ["firefox", "firefox-esr"]'
qst key BackSpace BackSpace BackSpace BackSpace BackSpace
qst wait '.field == ""'
qst type browser
qst wait '.results == ["firefox"]'
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'nixpkgs-run qs-test firefox firefox$' || { qst actions; echo "Return did not run firefox"; exit 1; }

qst case "the window switcher keeps its selection while a window retitles under it"
export QS_TEST_MONITORS="DP-1:1920x1080:1"
qst reset > /dev/null
qst spawn foot -a one sleep 600
qst spawn foot -a two sh -c 'while :; do printf "\033]2;%s\007" "$(date +%N)"; sleep 0.2; done' # sleep: the window retitles itself, as a terminal or a browser tab does
qst spawn foot -a three sleep 600
qst wait '(.windows | length) == 3' 10
qst key super+Tab
qst wait '.panel == "windows" and (.results | length) == 3'
qst key Down
picked=$(qst state .selected)
qst stays ".selected == $picked" 1.5

qst case "the clipboard searches a clip's own text, never the counts under it"
export QS_TEST_MONITORS="DP-1:1920x1080:1"
qst reset > /dev/null
echo "a clip to find" | cliphist store
qst key super+v
qst wait '.panel == "clipboard" and (.results | index("a clip to find")) != null'
# The cache pass that counts each clip's characters and lines.
qst stays '.panel == "clipboard"' 0.5
qst type character
qst stays '.panel == "clipboard" and all(.results[]; test("character"; "i"))' 0.5
