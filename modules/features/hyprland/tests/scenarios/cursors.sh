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

qst case "a hand over a tray menu's rows"
qst tray
qst wait '.tray | length > 0'
# The tray's icon, last on the bar.
qst click right $((1920 - 31)) 20
qst wait '.panel == "tray:DP-1"'
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
