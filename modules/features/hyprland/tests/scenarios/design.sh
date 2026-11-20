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
  qst stays '(.popups | length) > 0' 1
  for panel in apps clipboard monitors windows nixpkgs center shortcuts power; do
    qst ipc panels open "$panel" > /dev/null
    qst wait ".panel == \"$panel\""
    qst stays ".panel == \"$panel\"" 0.6
  done
  qst ipc panels close > /dev/null
  qst wait '.panel == ""'
done

qst case "the volume popup, a tray menu, the OSD and the privacy tooltip"
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
qst stays '.panel == "volume:DP-1"' 0.6
qst ipc panels close > /dev/null
qst tray
qst wait '.tray | length > 0'
# The tray's icon, last on the bar.
qst click right $((1920 - 31)) 20
qst wait '.panel == "tray:DP-1"'
qst stays '.panel == "tray:DP-1"' 0.6
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3
qst wait '.osd.kind == "volume"'
qst stays '.osd != null' 0.4
qst camera open zoom
qst wait '.privacy.camera == ["zoom"]'
qst ipc panels close > /dev/null
qst wait '.panel == ""'
read -r x y _ < <(qst areas 'BarWindow/PrivacyIndicator')
qst pointer "$x" "$y"
qst pointer $((x + 1)) "$y"
qst wait '.layers | any(endswith(" quickshell:privacy"))'
qst stays '.privacy.camera == ["zoom"]' 1
