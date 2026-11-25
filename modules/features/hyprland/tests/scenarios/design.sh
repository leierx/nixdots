export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# Every wait and stays runs the probe's census; these only bring each piece on screen, on a scaled monitor too.
notifications() {
  local icon=$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg
  notify-send -a Chat "A plain one" "with a body"
  notify-send -a Firefox -i firefox "An app's icon by name" "and a link: <a href=\"https://example.org\">example</a>"
  notify-send -a Ghost -i qst-no-such-icon "An icon nobody has" "so its initial stands in"
  notify-send -a Pictures -i "$icon" "A picture" "drawn from a file"
  notify-send -u critical -a Battery "Critical" "10 % left"
  notify-send -a Download -h int:value:40 "Progress" "40 %"
  notify-send -a Chat "A long one" "$(printf 'A line that goes on and on, long enough to wrap and then some. %.0s' 1 2 3 4 5 6)"
  qst wait '.notifications == 7'
}

for monitor in DP-1 DP-2; do
  qst case "the bar, popups and every panel on $monitor"
  qst focus "$monitor"
  notifications
  echo "a clip to show" | cliphist store
  echo "https://example.org/a/link" | cliphist store
  qst stays '(.popups | length) > 0' 1
  for panel in apps clipboard monitors windows nixpkgs center shortcuts power; do
    qst ipc panels open "$panel" > /dev/null
    qst wait "(.panel | startswith(\"$panel\"))"
    qst stays "(.panel | startswith(\"$panel\"))" 0.6
  done
  qst ipc panels close > /dev/null
  qst wait '.panel == ""'
done

qst case "the control centre with each of its menus, a tray menu, the OSD and an In Use pill"
qst bluetooth add 11:22:33:44:55:01 "WH-1000XM4" audio-headset ok paired connected 70
qst player add spotify Spotify Playing "$QS_TEST_DIR/shell/weather/icons/clearsky_day.svg"
qst backlight intel_backlight 600 1000
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.media != null'
for menu in sound wifi vpn bluetooth night; do
  qst ipc controls menu "$menu" > /dev/null
  qst stays ".controls.menu == \"$menu\" and .panel == \"controls:DP-1\"" 0.6
done
qst ipc controls menu "" > /dev/null
qst ipc panels close > /dev/null
qst tray
qst wait '.tray | length > 0'
# The tray revealed on the bar's right end, then the first icon's menu.
qst pointer 1850 16
qst wait '.trays[0].shown'
qst stays '.trays[0].shown' 0.3
read -r x y _ < <(qst areas BarWindow | awk -F'\t' '$1 > 1000 && $1 < 1840 && $5 == "true" && $6 == "false" && $2 < 32' | sort -n | head -1)
qst pointer "$x" "$y"
qst stays '.trays[0].shown' 0.6
qst click right "$x" "$y"
qst wait '.layers | any(endswith(" quickshell:menu"))'
qst stays '.panel == "tray-menu:DP-1"' 0.6
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3
qst wait '.osd.kind == "volume"'
qst stays '.osd != null' 0.4
qst camera open zoom
qst wait '.privacy.camera == ["zoom"]'
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst stays '.privacy.camera == ["zoom"] and .panel == "controls:DP-1"' 1

for monitor in DP-1 DP-2; do
  qst case "the gallery of every common piece in every state on $monitor"
  qst focus "$monitor"
  qst gallery
  qst wait '.panel == "gallery"'
  qst stays '.panel == "gallery"' 0.6
  qst pointer 960 600
  qst wheel 20
  qst stays '.panel == "gallery"' 0.6
done

qst case "the center with a player, notifications and the weather"
qst player add spotify Spotify Playing "$QS_TEST_DIR/shell/weather/icons/clearsky_day.svg"
notify-send -a Chat "Lunch at noon" "Meet at the usual place"
qst wait '.notifications == 1'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1" and .controls.media != null'
qst stays '.panel == "center:DP-1"' 0.6

# Qt's own locale data, whatever glibc has: long words, another script, other digits; a time zone fourteen hours on.
for locale in de_DE fi_FI ar_EG; do
  QS_TEST_LOCALE=$locale.UTF-8 TZ=Pacific/Kiritimati qst case "the bar, the center, the control centre and the power menu in $locale"
  # Qt's, as glibc on the machine may lack the locale; Qt has its own.
  qst expect --may 'Detected locale "C" with character encoding'
  notifications
  for panel in center controls power shortcuts; do
    qst ipc panels open "$panel" > /dev/null
    qst wait "(.panel | startswith(\"$panel\"))"
    qst stays "(.panel | startswith(\"$panel\"))" 0.6
  done
done
