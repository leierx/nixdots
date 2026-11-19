dir=${1:-/sys/class/backlight}

report() {
  local line="" device brightness max
  for device in "$dir"/*/; do
    device=${device%/}
    brightness=$(cat "$device/actual_brightness" 2> /dev/null || cat "$device/brightness" 2> /dev/null) || continue
    max=$(cat "$device/max_brightness" 2> /dev/null) || continue
    line+="${device##*/} $brightness $max;"
  done
  printf '%s\n' "$line"
}

# The kernel sends a change uevent for every brightness set however it was made, and add and remove
# for every backlight. Listening starts before the first report, so nothing falls between them, and
# udevadm goes with this script rather than at its next event.
exec {events}< <(udevadm monitor --udev --subsystem-match=backlight)
monitor=$!
trap 'kill "$monitor" 2> /dev/null' EXIT
trap 'exit 0' TERM INT HUP
report
while IFS= read -r event <&"$events"; do
  case $event in "UDEV "*"["*) report ;; esac
done
