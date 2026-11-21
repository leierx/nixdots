export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "windows that open while the shell starts mark their workspace occupied"
# Quickshell warns of each window it drops this way, which the bar makes up for.
qst expect --may 'Got openwindow for workspace ".*" which was not previously tracked'
qst sync > /dev/null &
syncing=$!
for _ in $(seq 12); do
  (wezterm start --always-new-process > /dev/null 2>&1 &)
  sleep 0.12 # sleep: spread over the shell's start, so some open before it has loaded the workspaces
done
wait "$syncing"
qst wait '(.windows | length) == 12 and (.workspaces | map(select(.id == 1))[0].windows) == 12' 15

qst case "a wheel spun hard over the workspaces moves one a notch, as far as the ends"
read -r x y _ < <(qst areas 'BarWindow' | awk -F'\t' '$6 == "true"' | sort -n | head -1)
qst pointer "$x" "$y"
qst wait '.monitors[0].workspace == 1'
qst spin 4
qst wait '.monitors[0].workspace == 5'
qst stays '.monitors[0].workspace == 5' 0.5
qst spin 20
qst wait '.monitors[0].workspace == 6'
qst spin -20
qst wait '.monitors[0].workspace == 1'
qst stays '.monitors[0].workspace == 1' 0.5
