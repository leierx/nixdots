export QS_TEST_MONITORS="DP-1:1920x1080:1"

# `qst cursors WINDOW` hovers every mouse area there that asks for a hand and fails where something else wins.

# The control centre with a headset and a player in, and MENU open if given.
controls() {
  qst bluetooth add 11:22:33:44:55:01 "WH-1000XM4" audio-headset ok paired connected 70
  qst player add spotify Spotify
  qst ipc panels open controls:DP-1 > /dev/null
  qst wait '.panel == "controls:DP-1" and .controls.media != null'
  if [ -n "${1:-}" ]; then
    qst ipc controls menu "$1" > /dev/null
    qst wait ".controls.menu == \"$1\""
  fi
  # Until its areas hold still: the centre grows open, and a menu eases open and fills as it scans.
  local before="" now
  for _ in $(seq 50); do
    now=$(qst areas ControlsPanel)
    [ "$now" = "$before" ] && return
    before=$now
    qst stays true 0.1
  done
  echo "the control centre never held still" >&2
  exit 1
}
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

qst case "a hand over everything clickable in the control centre"
controls
qst cursors ControlsPanel

# A case per menu, each a sweep of its own, so they run side by side.
qst case "a hand over everything clickable in the control centre's Wi-Fi menu"
controls wifi
qst cursors ControlsPanel

qst case "a hand over everything clickable in the control centre's VPN menu"
controls vpn
qst cursors ControlsPanel

qst case "a hand over everything clickable in the control centre's Bluetooth menu"
controls bluetooth
qst cursors ControlsPanel

qst case "a hand over everything clickable in the control centre's output menu"
controls output
qst cursors ControlsPanel

qst case "a hand over everything clickable in the control centre's input menu"
controls input
qst cursors ControlsPanel

qst case "a hand over everything clickable in the control centre's night light menu"
controls night
qst cursors ControlsPanel

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

qst case "a hand over every piece in the gallery that takes a click"
qst gallery
qst wait '.panel == "gallery"'
qst cursors GalleryWindow

qst case "a hand over everything clickable in the center with a player in"
qst player add spotify Spotify
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and .controls.media != null'
qst cursors NotificationCenter
