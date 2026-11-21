export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

layer() { echo "(.layers | index(\"$1\")) != null"; }
no_layer() { echo "(.layers | map(select(endswith(\" $1\"))) | length) == 0"; }
no_problems() {
  local found
  found=$(qst problems)
  [ -z "$found" ] || { echo "$found"; exit 1; }
}

for panel in apps:launcher clipboard:launcher monitors:launcher windows:launcher center:center shortcuts:shortcuts power:power; do
  name=${panel%%:*}
  namespace=quickshell:${panel#*:}
  qst case "$name closes with its monitor and opens again with one press"
  qst focus DP-2
  qst ipc panels toggle "$name"
  qst wait "$(layer "DP-2 $namespace") and .panel == \"$name\""
  qst monitor remove DP-2
  qst wait "$(no_layer "$namespace") and .panel == \"\""
  qst ipc panels toggle "$name"
  qst wait "$(layer "DP-1 $namespace") and .panel == \"$name\""
  no_problems
done

qst case "the launcher's shortcut opens it again after its monitor went"
qst focus DP-2
qst key super+d
qst wait "$(layer "DP-2 quickshell:launcher")"
qst monitor remove DP-2
qst wait "$(no_layer quickshell:launcher)"
qst key super+d
qst wait "$(layer "DP-1 quickshell:launcher") and .panel == \"apps\""

qst case "a panel stays open while another monitor comes and goes"
qst ipc panels open apps
qst wait "$(layer "DP-1 quickshell:launcher")"
qst monitor remove DP-2
qst stays "$(layer "DP-1 quickshell:launcher") and .panel == \"apps\""
qst monitor add DP-3 1920x1080 1
qst wait '.screens | length == 2'
qst stays "$(layer "DP-1 quickshell:launcher") and .panel == \"apps\""

qst case "a tray menu closes with its monitor"
qst tray
qst wait '.tray | length > 0'
# The tray on the bar's right end (X there, left of its status button), then its first icon's menu by a right click.
tray_menu() {
  local x y
  qst pointer "$1" 16
  qst wait "(.trays | map(select(.screen == \"$2\")))[0].shown"
  qst stays "(.trays | map(select(.screen == \"$2\")))[0].shown" 0.3
  read -r x y _ < <(qst areas BarWindow | awk -F'\t' -v lo=$(($1 - 400)) -v hi="$1" '$1 > lo && $1 < hi && $5 == "true" && $6 == "false" && $2 < 32' | sort -n | head -1)
  qst pointer "$x" "$y"
  qst click right "$x" "$y"
  qst wait "$(layer "$2 quickshell:menu")"
}
tray_menu $((1920 + 2048 - 70)) DP-2
qst monitor remove DP-2
qst wait "$(no_layer quickshell:menu) and .panel == \"\""
tray_menu 1850 DP-1

qst case "a popup leaves a monitor that goes, and stays where it went"
qst focus DP-2
notify-send -t 0 -a Test "on DP-2"
qst wait '.popups | map(.screen) == ["DP-2"]'
qst monitor remove DP-2
qst wait '.popups | map(.screen) == ["DP-1"]'
qst monitor add DP-2 2560x1440 1.25
qst wait '.screens | length == 2'
qst stays '.popups | map(.screen) == ["DP-1"]'

qst case "a popup goes to the focused monitor when its own goes, wherever Hyprland moves the focus"
qst monitor add DP-3 1920x1080 1
qst wait '.screens | length == 3'
qst focus DP-2
notify-send -t 0 -a Test "on DP-2"
qst wait '.popups | map(.screen) == ["DP-2"]'
qst focus DP-3
qst monitor remove DP-2
qst wait '(.popups | map(.screen)) == [.hypr[] | select(.focused) | .name]'

qst case "a disabled monitor loses its bar and popups, and gets them back enabled"
qst focus DP-2
notify-send -t 0 -a Test "on DP-2"
qst wait '.popups | map(.screen) == ["DP-2"]'
qst monitor disable DP-2
qst wait "(.screens | map(.name)) == [\"DP-1\"] and (.layers | index(\"DP-2 quickshell:bar\")) == null"
qst wait '.popups | map(.screen) == ["DP-1"]'
qst monitor enable DP-2
qst wait "$(layer "DP-2 quickshell:bar") and $(layer "DP-2 quickshell:notifications")"
qst wait '(.screens | map(.monitor) | sort) == [0, 1]'

qst case "with every monitor gone the shell shows nothing, opens nothing and holds its popups"
qst monitor remove DP-1
qst monitor remove DP-2
qst wait '(.screens | map(.name)) == ["FALLBACK"] and (.layers | map(select(contains("quickshell"))) | length) == 0'
notify-send -t 1000 -a Test "while none"
qst wait '.popups | map(.screen) == [""]'
qst ipc panels open apps
qst stays '.panel == "" and (.popups | length) == 1' 2
qst monitor add DP-1 1920x1080 1 0x0
qst wait '.popups | map(.screen) == ["DP-1"]'
qst wait "$(layer "DP-1 quickshell:notifications") and $(layer "DP-1 quickshell:bar")"
qst wait '.popups == []' 4
qst wait '.workspaces | map(.label) | any(startswith("FALLBACK")) | not'
no_problems

qst case "two monitors back at once from none each get their own bar"
qst monitor remove DP-1
qst monitor remove DP-2
qst wait '(.screens | map(.name)) == ["FALLBACK"]'
qst monitor add DP-1 1920x1080 1 0x0
qst monitor add DP-2 2560x1440 1.25
qst wait "$(layer "DP-1 quickshell:bar") and $(layer "DP-2 quickshell:bar") and (.layers | map(select(endswith(\" quickshell:bar\"))) | length) == 2"
qst wait "$(layer "DP-1 quickshell:notifications") and $(layer "DP-2 quickshell:notifications")"
no_problems

qst case "a workspace left by an unplugged monitor keeps its owner's name, and its window says so"
qst focus DP-2
qst key super+Return
qst wait '.windows | map(.workspace) == [7]' 10
qst monitor remove DP-2
qst wait '.workspaces | map(select(.id == 7)) == [{ id: 7, monitor: "DP-1", label: "DP2-1", windows: 1 }]'
qst key super+Tab
qst wait "$(layer "DP-1 quickshell:launcher")"
qst shot windows DP-1 > /dev/null

qst case "a burst of hotplugs settles on the right monitors"
for _ in 1 2 3 4 5; do
  qst monitor remove DP-2
  qst monitor add DP-2 2560x1440 1.25
done
qst monitor remove DP-1
qst monitor add DP-1 1920x1080 1 0x0
qst wait '(.screens | length) == 2 and all(.screens[]; .monitor != null) and ([.hypr[] | {name, id}] | sort) == ([.monitors[] | {name, id}] | sort)' 10
qst wait "$(layer "DP-1 quickshell:bar") and $(layer "DP-2 quickshell:bar") and (.layers | map(select(endswith(\" quickshell:bar\"))) | length) == 2"
no_problems

qst case "a mode change keeps an open panel open"
qst ipc panels open center
qst wait "$(layer "DP-1 quickshell:center")"
qst output 1280x720 1
qst wait '.screens[0].width <= 1280'
qst stays "$(layer "DP-1 quickshell:center") and .panel == \"center\""
no_problems
