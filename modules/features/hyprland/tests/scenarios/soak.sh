export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# One shell used for long, against random input and over and over: what a case that starts fresh never sees.

pid() { qst status | awk '{ print $NF }'; }
rss() { awk '/VmRSS/ { print int($2 / 1024) }' "/proc/$1/status"; }
fds() { find "/proc/$1/fd" -mindepth 1 -maxdepth 1 | wc -l; }
ticks() { awk '{ print $14 + $15 }' "/proc/$1/stat"; }

qst case "four hundred random actions with a tray, a player and a camera about end with every invariant holding"
qst tray add soak 3
qst player add spotify Spotify
qst camera open zoom
qst wait '(.tray | length) == 3 and .controls.media != null' 10
# QS_TEST_SEED replays a run: the seed is the first thing it prints.
qst fuzz 400 ${QS_TEST_SEED:+"$QS_TEST_SEED"}
qst ipc panels close > /dev/null
qst ipc idle unlocked > /dev/null
qst wait '.panel == ""'

qst case "every panel opened and closed fifty times gives its memory and its files back"
cycle() {
  for panel in apps clipboard center controls shortcuts power monitors windows; do
    qst ipc panels open "$panel" > /dev/null
    qst wait "(.panel | startswith(\"$panel\"))"
    qst ipc panels close > /dev/null
    qst wait '.panel == ""'
  done
}
shell=$(pid)
# The first rounds fill the caches and the pixmaps; what grows after is kept by nothing.
for _ in 1 2 3; do cycle; done
qst ipc probe churn 1 > /dev/null
before=$(rss "$shell") files=$(fds "$shell")
for _ in $(seq 50); do cycle; done
qst ipc probe churn 1 > /dev/null
after=$(rss "$shell")
[ $((after - before)) -le 40 ] || { echo "RSS grew from $before MiB to $after MiB over 400 opens"; exit 1; }
[ "$(fds "$shell")" -le $((files + 4)) ] || { echo "open files grew from $files to $(fds "$shell") over 400 opens"; exit 1; }

qst case "an idle shell sleeps: a few percent of a core with nothing happening, a popup or a player on screen"
# alone: it measures the shell's CPU, which a loaded machine's scheduling would add to
shell=$(pid)
qst player add spotify Spotify Paused
notify-send -t 0 -a Chat "a popup that stays"
qst wait '(.popups | length) == 1 and .controls.media != null'
qst stays '(.popups | length) == 1' 1
start=$(ticks "$shell")
sleep 10 # sleep: the probe itself would cost the CPU this measures
used=$(($(ticks "$shell") - start))
# Clock ticks of 10 ms: 30 in 10 s is 3 % of a core.
[ "$used" -le 30 ] || { echo "the shell used $used ticks of CPU in 10 s doing nothing"; exit 1; }

qst case "the package list at its real size, searched and let go of a minute after the launcher closes, gives its memory back"
# alone: it measures the shell's memory, which a loaded machine's slower frames would leave less settled
shell=$(pid)
list=$(qst state .cache | jq -r .)/nixpkgs.tsv
mkdir -p "$(dirname "$list")"
# Its first line names the fake's own list, which it then leaves as it is; lines as long as the channel's.
{ printf 'qs-test\tqs-test\n'; awk 'BEGIN { for (i = 0; i < 133000; i++) printf "pkgs.group%d.package%d\tprogram%d\t%d.%d.%d\t%s\tA description of package number %d, as long as most in the channel\n", i % 97, i, i, i % 7, i % 13, i % 3, i % 50 == 0 ? "unfree" : "", i }'; } > "$list"
before=$(rss "$shell")
qst key super+n
qst wait '.panel == "nixpkgs"'
qst type package12345
qst wait '.results[0] == "pkgs.group26.package12345"' 15
qst key ctrl+a BackSpace
qst type e
qst wait '.field == "e" and (.results | length) == 10'
open=$(rss "$shell")
qst key Escape
qst wait '.panel == ""'
qst stays '.panel == ""' 62
after=$(rss "$shell")
[ $((after - before)) -le 30 ] || { echo "RSS was $before MiB, $open MiB with the list, and $after MiB a minute after it was let go"; exit 1; }
