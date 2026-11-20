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
