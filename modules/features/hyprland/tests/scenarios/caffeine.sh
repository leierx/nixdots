export QS_TEST_MONITORS="DP-1:1920x1080:1"

qst case "Caffeine starts its unit, and stops it"
qst wait '.caffeine == false'
qst ipc caffeine toggle
qst wait '.caffeine'
qst actions | grep -qx 'systemctl --user start caffeine.service'
qst ipc caffeine toggle
qst wait '.caffeine == false'
qst actions | grep -qx 'systemctl --user stop caffeine.service'

qst case "a unit started elsewhere shows, and one that stops by itself goes"
systemctl --user start caffeine.service
qst wait '.caffeine' 7
systemctl --user stop caffeine.service
qst wait '.caffeine == false' 7

qst case "with the center open a change elsewhere shows sooner"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
systemctl --user start caffeine.service
qst wait '.caffeine' 3

qst case "it outlives a restart of the shell"
qst ipc caffeine set true
qst wait '.caffeine'
qst restart > /dev/null
qst wait '.caffeine'

qst case "a click on the bar's cup turns it off, opening nothing"
qst ipc caffeine set true
qst wait '.caffeine'
# The cup, last on the bar with no tray items and no bell.
qst pointer 1890 21
qst click left 1894 21
qst wait '.caffeine == false'
qst stays '.panel == ""' 1
