export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "Keep Awake starts its unit, and stops it"
qst wait '.keepAwake == false'
qst ipc keepAwake toggle
qst wait '.keepAwake'
qst actions | grep -qx 'systemctl --user start keep-awake.service'
qst ipc keepAwake toggle
qst wait '.keepAwake == false'
qst actions | grep -qx 'systemctl --user stop keep-awake.service'

qst case "a unit started elsewhere shows, and one that stops by itself goes"
systemctl --user start keep-awake.service
qst wait '.keepAwake' 7
systemctl --user stop keep-awake.service
qst wait '.keepAwake == false' 7

qst case "with the center open a change elsewhere shows sooner"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
systemctl --user start keep-awake.service
qst wait '.keepAwake' 3

qst case "it outlives a restart of the shell"
qst ipc keepAwake set true
qst wait '.keepAwake'
qst restart > /dev/null
qst wait '.keepAwake'
