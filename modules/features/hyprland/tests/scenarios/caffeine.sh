export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "Caffeine starts its unit, and stops it"
qst wait '.caffeine == false'
qst ipc caffeine toggle
qst wait '.caffeine'
qst actions | grep -qx 'systemctl --user start caffeine.service'
qst ipc caffeine toggle
qst wait '.caffeine == false'
qst actions | grep -qx 'systemctl --user stop caffeine.service'

qst case "a second toggle while systemctl still runs the first is not lost"
qst wait '.caffeine == false'
qst x sh -c 'shell=${XDG_CONFIG_HOME%/cfg}/shell; qs ipc -p "$shell" call caffeine toggle & qs ipc -p "$shell" call caffeine toggle; wait'
qst stays '.caffeine == false' 2
qst actions | grep -qx 'systemctl --user stop caffeine.service'
qst x sh -c '[ ! -e "${XDG_CONFIG_HOME%/cfg}/units/caffeine.service" ]'

qst case "a unit started elsewhere shows, and one that stops by itself goes"
systemctl --user start caffeine.service
qst wait '.caffeine' 7
systemctl --user stop caffeine.service
qst wait '.caffeine == false' 7

qst case "with the control centre open a change elsewhere shows sooner"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
systemctl --user start caffeine.service
qst wait '.caffeine' 3

qst case "it outlives a restart of the shell"
qst ipc caffeine set true
qst wait '.caffeine'
qst restart > /dev/null
qst wait '.caffeine'

qst case "the control centre's Caffeine pill, beside Night Light, turns it on and off, and the status button shows a cup while it is on"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst wait '([.controls.toggles[].key] | index("caffeine")) == ([.controls.toggles[].key] | index("night")) + 1'
qst click ControlsPanel:pill:caffeine
qst wait '.caffeine and (.status[0].glyphs | index("caffeine")) != null'
qst actions | grep -qx 'systemctl --user start caffeine.service'
qst click ControlsPanel:pill:caffeine
qst wait '(.caffeine | not) and (.status[0].glyphs | index("caffeine")) == null'

QS_TEST_COLD=1 qst case "a shell nobody has looked at yet takes Caffeine from a script"
[ "$(qst ipc caffeine toggle)" = "" ] || { echo "the caffeine target did not answer on a cold shell"; exit 1; }
for _ in $(seq 30); do [ -e "$QS_TEST_DIR/units/caffeine.service" ] && break; sleep 0.1; done # sleep: the probe would read the singleton this case leaves unread
[ -e "$QS_TEST_DIR/units/caffeine.service" ] || { qst actions; echo "Caffeine did not start its unit"; exit 1; }
