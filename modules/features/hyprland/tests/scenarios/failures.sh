export QS_TEST_MONITORS="DP-1:1920x1080:1"

# What the shell runs failing as it can: the shell stays up, says so where someone waits on it, and its panel still opens and closes.
reopens() {
  qst ipc panels open "$1" > /dev/null
  qst wait ".panel == \"$1\""
  qst ipc panels close > /dev/null
  qst wait '.panel == ""'
}

notified() { qst wait "any(.history[]; .summary == \"$1\")"; }

qst case "a clipboard whose cliphist fails, or is not installed, says so"
qst fail cliphist exit
qst ipc panels open clipboard > /dev/null
qst wait '.notifications == 1 and .history[0].summary == "cliphist list" and .panel == ""'
qst fail cliphist missing
qst expect 'Process failed to start, likely because the binary could not be found'
qst ipc panels open clipboard > /dev/null
qst wait '.notifications == 2 and .history[0].summary == "cliphist list" and .panel == ""'
qst fail cliphist off
reopens clipboard

qst case "monitor layouts outlive hyprmoncfg failing and writing garbage"
qst fail hyprmoncfg exit
qst expect 'hyprmoncfg'
reopens monitors
qst fail hyprmoncfg garbage
qst expect 'hyprmoncfg status: SyntaxError'
reopens monitors

qst case "the shortcuts window says when hyprctl fails"
qst fail hyprctl exit
qst ipc panels open shortcuts > /dev/null
notified "hyprctl binds -j"
qst wait '.panel == ""'

qst case "Caffeine says when systemctl fails, and stays off"
qst fail systemctl exit
qst ipc caffeine toggle
notified "Caffeine"
qst stays '.caffeine == false' 1

qst case "the camera watcher crashing is started again, and the weather waits when curl fails"
qst fail camera-users crash
qst fail curl exit
qst restart > /dev/null
qst expect 'camera-users stopped, starting it again'
qst expect 'Weather: fetching the forecast'
qst stays '.privacy.camera == null' 1
reopens center
