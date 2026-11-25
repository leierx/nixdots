export QS_TEST_MONITORS="DP-1:1920x1080:1"

# The wall clock moving under the shell (`qst clock`, the shell's alone): a suspend's gap, the shell frozen through one (`qst suspend`), a clock set back, midnight, Oslo's clock changes.

fetches() { qst actions | grep -c 'api\.met\.no' || true; }

QS_TEST_CLOCK=1 qst case "eight hours gone at once, as after a suspend, fetch the forecast once more and move the clock"
qst wait '.weather.hours > 0' 10
before=$(fetches)
was=$(qst state .now | jq -r .)
qst clock +8h
qst wait ".now != \"$was\" and .weather.hours > 0"
for _ in $(seq 50); do [ "$(fetches)" -gt "$before" ] && break; qst stays true 0.1; done
[ "$(fetches)" = $((before + 1)) ] || { qst actions; echo "the forecast was fetched $(($(fetches) - before)) times after the gap, not once"; exit 1; }
qst stays '.weather.hours > 0' 2
[ "$(fetches)" = $((before + 1)) ] || { qst actions; echo "the forecast went on being fetched"; exit 1; }

QS_TEST_CLOCK=1 qst case "a suspend: the shell and its helpers frozen while eight hours pass wake on the hour it is, with what came meanwhile, one forecast fetch and no popup left for good"
qst wait '.weather.hours > 0' 10
before=$(fetches)
was=$(qst state .now | jq -r .)
notify-send -a Mail "before"
qst wait '(.popups | length) == 1'
qst suspend +8h 2 &
# Its reply waits on the frozen shell.
notify-send -a Chat "meanwhile" &
wait
qst wait ".now != \"$was\" and any(.history[]; .summary == \"meanwhile\")"
now=$(qst state .now | jq -r .)
# A minute may turn between the two reads.
[ "$now" = "$(date -d '+8 hours' '+%Y-%m-%d %H:%M')" ] || [ "$now" = "$(date -d '+8 hours -1 minute' '+%Y-%m-%d %H:%M')" ] || { echo "the clock says $now, not eight hours on"; exit 1; }
for _ in $(seq 50); do [ "$(fetches)" -gt "$before" ] && break; qst stays true 0.1; done
[ "$(fetches)" = $((before + 1)) ] || { qst actions; echo "the forecast was fetched $(($(fetches) - before)) times after the suspend, not once"; exit 1; }
qst wait '.popups == []' 15
qst stays '.notifications == 2 and .weather.hours > 0' 1

QS_TEST_CLOCK=1 qst case "the clock set back an hour keeps the newest notification first, and the next above it"
notify-send -a Mail "first"
qst wait '.notifications == 1'
qst clock -1h
notify-send -a Chat "second"
qst wait '(.history | map(.summary)) == ["second", "first"]'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst stays '.center[0].app == "Chat"' 1

TZ=Europe/Oslo QS_TEST_CLOCK=1 qst case "midnight and both of Oslo's clock changes pass under the open center"
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
qst clock at "2026-12-31 22:59:50 UTC"
qst wait '.now == "2026-12-31 23:59"'
qst wait '.now == "2027-01-01 00:00"' 15
# Spring: 02:00 does not happen.
qst clock at "2027-03-28 00:59:50 UTC"
qst wait '.now == "2027-03-28 01:59"'
qst wait '.now == "2027-03-28 03:00"' 15
# Autumn: 03:00 summer time is 02:00 again.
qst clock at "2027-10-31 00:59:50 UTC"
qst wait '.now == "2027-10-31 02:59"'
qst wait '.now == "2027-10-31 02:00"' 15
qst stays '.panel == "center:DP-1"' 1
