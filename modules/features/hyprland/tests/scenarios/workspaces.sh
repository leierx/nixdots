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
