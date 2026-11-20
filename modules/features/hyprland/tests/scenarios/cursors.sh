export QS_TEST_MONITORS="DP-1:1920x1080:1"

# `qst cursors WINDOW` hovers every mouse area there that asks for a hand and fails where something else wins.
qst case "a hand over everything clickable, on the bar, popups and in every panel"
notify-send -a Chat "one" "a body"
notify-send -a Chat "two" "another body"
qst wait '.notifications == 2'
qst cursors BarWindow
qst cursors NotificationPopups
for panel in apps:LauncherWindow clipboard:LauncherWindow monitors:LauncherWindow windows:LauncherWindow center:NotificationCenter shortcuts:ShortcutsWindow power:PowerMenu; do
  qst ipc panels open "${panel%%:*}" > /dev/null
  qst wait ".panel == \"${panel%%:*}\""
  qst cursors "${panel#*:}"
done

qst case "a hand over everything clickable in the control centre, with each of its menus open"
qst bluetooth add 11:22:33:44:55:01 "WH-1000XM4" audio-headset ok paired connected 70
qst player add spotify Spotify
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.media != null'
qst cursors ControlsPanel
for menu in wifi vpn bluetooth output input night; do
  qst ipc controls menu "$menu" > /dev/null
  qst wait ".controls.menu == \"$menu\""
  qst cursors ControlsPanel
done

qst case "a hand over a tray menu's rows"
qst tray
qst wait '.tray | length > 0'
# The tray's chevron, last on the bar, then the first icon's menu.
qst click left $((1920 - 21)) 17
qst wait '.panel == "tray-overflow:DP-1"'
qst cursors TrayOverflow
read -r x y _ < <(qst areas 'TrayOverflow' | awk -F'\t' '$2 > 30' | sort -n -k2 | head -1)
qst click right "$x" "$y"
qst wait '.layers | any(endswith(" quickshell:menu"))'
qst cursors TrayMenu

qst case "a closed hand while a popup is dragged"
notify-send -t 0 -a Chat "drag me"
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst pointer "$x" "$y"
qst press left
qst pointer $((x + 40)) "$y"
qst cursor $((x + 60)) "$y" closed
qst release left
