export QS_TEST_MONITORS="DP-1:1920x1080:1"

# Behaviour that broke once and had no case of its own.

qst case "a click expands a long popup, a second collapses it, and neither puts it away"
notify-send -t 0 -a Chat "A long one" "$(printf 'A line that goes on and on, long enough to wrap and then some. %.0s' 1 2 3 4 5 6)"
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst click left "$x" "$y"
qst stays '(.popups | length) == 1' 0.5
qst click left "$x" "$y"
qst stays '(.popups | length) == 1' 1

qst case "the wheel over the volume never turns down a level another app set past 100 %"
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.3
qst wait '.volume.percent == 130'
# The volume is the first button on the right of the bar while nothing records and nothing waits unchecked.
read -r x y _ < <(qst areas 'BarWindow/' | awk '$1 > 1600' | head -1)
qst pointer "$x" "$y"
qst wheel -1
qst stays '.volume.percent == 130' 1
qst wheel 1
qst wait '.volume.percent == 125'

qst case "a picked clip is handed to wl-copy in a scope of its own, so a restart of the shell keeps it"
echo "a clip to pick" | cliphist store
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard"'
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'systemd-run.*--scope.*wl-copy' || { qst actions; echo "the clip was not handed over in a scope"; exit 1; }

qst case "every panel fits a 1024x600 screen"
qst output 1024x600 1
qst wait '.screens[0].width <= 1024'
for panel in apps clipboard monitors windows nixpkgs center shortcuts power controls:DP-1; do
  qst ipc panels open "$panel" > /dev/null
  qst wait ".panel == \"$panel\""
  qst stays ".panel == \"$panel\"" 0.6
done

qst case "Power Off takes a second press, and moving the selection disarms it"
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key p
qst stays '.panel == "power"' 0.5
qst actions | grep -q poweroff && { echo "one press powered off"; exit 1; }
qst key Left p
qst stays '.panel == "power"' 0.5
qst actions | grep -q poweroff && { echo "a press after moving powered off"; exit 1; }
qst key p
qst wait '.panel == ""'
qst actions | grep -q 'systemctl poweroff' || { echo "two presses did not power off"; exit 1; }
