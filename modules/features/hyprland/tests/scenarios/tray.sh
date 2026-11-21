export QS_TEST_MONITORS="DP-1:1920x1080:1"

# The tray lives on the bar, left of the status button: three icons always, the rest as the pointer reaches the bar's right end.
reveal() {
  qst pointer 1850 16
  qst wait '.trays[0].shown and .trays[0].more == 0'
  # Until the strip has finished sliding out, so its cells hold still.
  qst stays '.trays[0].shown' 0.3
}

# The Nth tray cell from the left on DP-1's bar, as "x y": the tray's cells are the hand-less areas left of the status button.
cell() {
  qst areas BarWindow | awk -F'\t' '$1 > 1000 && $1 < 1840 && $5 == "true" && $6 == "false" && $2 < 32' | sort -n | sed -n "${1}p" | awk -F'\t' '{ print $1, $2 }'
}

qst case "three tray icons show always with a count of the rest, which come as the pointer reaches the bar's right end and linger a moment after it leaves; an empty tray is gone"
qst tray add first 5
qst wait '(.tray | length) == 5 and .trays[0].shown and .trays[0].more == 2 and (.trays[0].expanded | not)'
# The left of the bar and the clock do not expand it.
qst pointer 400 16
qst pointer 960 16
qst stays '.trays[0].more == 2' 0.5
reveal
qst wait '.trays[0].expanded'
qst pointer 900 600
# A near miss still finds it.
qst stays '.trays[0].expanded' 0.4
qst wait '(.trays[0].expanded | not) and .trays[0].more == 2' 2
qst tray clear
qst wait '(.tray | length) == 0 and (.trays[0].shown | not)'

qst case "past 12 em the strip scrolls sideways under the wheel, and stops at its ends"
qst tray add crowd 30
qst wait '(.tray | length) == 30' 10
reveal
qst wait '.trays[0].scrolls and .trays[0].offset == 0'
read -r x y < <(cell 2)
qst pointer "$x" "$y"
qst wheel 3
qst wait '.trays[0].offset > 0'
qst wheel 100
qst wait '.trays[0].offset > 0'
qst stays '.trays[0].shown' 0.3
qst wheel -100
qst wait '.trays[0].offset == 0'

qst case "a right click opens an item's menu at the pointer, which keeps the tray out, and the keys walk it"
qst tray
qst wait '.tray | length > 0'
reveal
read -r x y < <(cell 1)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.panel == "tray-menu:DP-1" and .trayMenu != null'
qst key Down
qst wait '.trayMenu.selected == "First item"'
qst key Up
qst wait '.trayMenu.selected == "Quit"'
qst key Up Up
qst wait '.trayMenu.selected == "Networks"'
qst key Right
qst wait '.trayMenu.path == ["Networks"] and .trayMenu.selected == "Network 0"'
qst key Left
qst wait '.trayMenu.path == [] and .trayMenu.selected == "Networks"'
# Away from the bar, the menu the keys drive keeps the tray out.
qst pointer 900 600
qst stays '.trayMenu != null and .trays[0].shown' 1
qst key Escape
qst wait '.panel == "" and .trayMenu == null'
qst wait '.trays[0].expanded | not' 2

qst case "Return on a tray menu's row triggers it and closes the menu"
qst tray
qst wait '.tray | length > 0'
reveal
read -r x y < <(cell 1)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst key Down Down Down Return
qst wait '.panel == "" and .trayMenu == null'
qst tray log | grep -qx 'qml: triggered Checkable true'

qst case "the keyboard skips a disabled row in a tray menu"
qst tray
qst wait '.tray | length > 0'
reveal
read -r x y < <(cell 1)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst key Down Down Down Down Down
qst wait '.trayMenu.selected == "With an icon"'

qst case "a second right click on the item closes its menu, and another panel opening closes it too"
qst tray
qst wait '.tray | length > 0'
reveal
read -r x y < <(cell 1)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst click right "$x" "$y"
qst wait '.trayMenu == null and .panel == ""'
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and .trayMenu == null'
