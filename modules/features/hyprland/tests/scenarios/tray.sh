export QS_TEST_MONITORS="DP-1:1920x1080:1"

open_overflow() {
  qst tray
  qst wait '.tray | length > 0'
  # The tray's chevron, last on the bar.
  qst click left $((1920 - 21)) 17
  qst wait '.panel == "tray-overflow:DP-1"'
}

qst case "the keyboard opens a tray icon's menu from the overflow and walks it"
open_overflow
qst key Right
qst wait '.trayFocus == 0'
qst key shift+F10
qst wait '.trayMenu.selected == "First item" and .panel == "tray-overflow:DP-1"'
# Round from the top to the bottom, past the separators.
qst key Up
qst wait '.trayMenu.selected == "Quit"'
qst key Up Up
qst wait '.trayMenu.selected == "Networks"'
qst key Right
qst wait '.trayMenu.path == ["Networks"] and .trayMenu.selected == "Network 0"'
qst key Up Return
qst wait '.trayMenu.path == ["Networks", "More networks"] and .trayMenu.selected == "Cafe"'
qst key Left
qst wait '.trayMenu.path == ["Networks"] and .trayMenu.selected == "More networks"'
qst key Left
qst wait '.trayMenu.path == [] and .trayMenu.selected == "Networks"'
# Without the pointer on it, a menu the keys drive stays.
qst stays '.trayMenu.selected == "Networks"' 1

qst case "Return on a tray menu's row triggers it and closes the overflow"
open_overflow
qst key Right Menu
qst wait '.trayMenu.selected == "First item"'
qst key Down Down Return
qst wait '.panel == "" and .trayMenu == null'
qst tray log | grep -qx 'qml: triggered Checkable true'

qst case "the keyboard skips a disabled row in a tray menu"
open_overflow
qst key Right Menu
qst key Down Down Down Down
qst wait '.trayMenu.selected == "With an icon"'

qst case "Escape takes the keyboard from a tray menu back to its icon, and a second Escape closes the overflow"
open_overflow
qst key Right Menu
qst wait '.trayMenu.selected == "First item"'
qst key Escape
qst wait '.trayMenu == null and .panel == "tray-overflow:DP-1" and .trayFocus == 0'
qst stays '.panel == "tray-overflow:DP-1"' 1
qst key Escape
qst wait '.panel == ""'

qst case "keys reach a tray menu opened with a right click"
open_overflow
read -r x y _ < <(qst areas 'TrayOverflow' | awk -F'\t' '$2 > 30' | sort -n -k2 | head -1)
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst key Down
qst wait '.trayMenu.selected == "First item"'
# The pointer leaving no longer closes it, as the keys have it.
qst pointer 400 600
qst stays '.trayMenu.selected == "First item"' 1
qst key Down Return
qst wait '.panel == ""'
qst tray log | grep -qx 'qml: triggered long label'

qst case "the pointer back on a tray menu the keys drove hands it back to the pointer"
open_overflow
qst key Right Menu
qst wait '.trayMenu.selected == "First item"'
read -r x y _ < <(qst areas 'TrayMenu' | sort -n -k2 | head -1)
qst pointer "$x" "$y"
qst wait '.trayMenu.keyed == false'
qst pointer 400 600
qst wait '.trayMenu == null and .panel == "tray-overflow:DP-1"'

qst case "up and down move a whole row through the overflow's grid"
qst tray add grid 14
qst wait '(.tray | length) == 14' 10
qst click left $((1920 - 21)) 17
qst wait '.panel == "tray-overflow:DP-1"'
qst key Right
qst wait '.trayFocus == 0'
qst key Down
qst wait '.trayFocus == 6'
qst key Down Down
qst wait '.trayFocus == 12'
qst key Up Left
qst wait '.trayFocus == 5'
