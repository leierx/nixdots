export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "windows that open while the shell starts mark their workspace occupied"
qst sync > /dev/null &
syncing=$!
# Spread over the shell's start, so some open before it has loaded the workspaces.
for _ in $(seq 12); do
  (wezterm start --always-new-process > /dev/null 2>&1 &)
  sleep 0.12
done
wait "$syncing"
qst wait '(.windows | length) == 12 and (.workspaces | map(select(.id == 1))[0].windows) == 12' 15
