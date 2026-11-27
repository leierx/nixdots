export QS_TEST_MONITORS="DP-1:1920x1080:1"

# Behaviour that broke once and had no case of its own.

qst case "a click on a popup runs its one action, as a banner never expands, and one without puts it away"
answer=$(mktemp)
notify-send -t 0 -a Chat -A reply=Reply "A long one" "$(printf 'A line that goes on and on, long enough to wrap and then some. %.0s' 1 2 3 4 5 6)" > "$answer" &
qst wait '(.popups | length) == 1'
read -r x y _ < <(qst areas 'NotificationPopups/SwipeArea' | head -1)
qst click left "$x" "$y"
qst wait '(.popups | length) == 0'
wait
grep -qx reply "$answer" || { echo "the click did not run the popup's one action"; exit 1; }
notify-send -t 0 -a Chat "A long one" "$(printf 'A line that goes on and on, long enough to wrap and then some. %.0s' 1 2 3 4 5 6)"
qst wait '(.popups | length) == 1'
qst click left "$x" "$y"
qst wait '(.popups | length) == 0 and .notifications == 1'

qst case "the wheel over the volume never turns down a level another app set past 100 %"
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.3
qst wait '.volume.percent == 130'
# The volume is the first button on the right of the bar while nothing records and nothing waits unchecked.
read -r x y _ < <(qst areas 'BarWindow/' | awk -F'\t' '$1 > 1600 && $6 == "true"' | head -1)
qst pointer "$x" "$y"
qst wheel -1
qst stays '.volume.percent == 130' 1
qst wheel 1
qst wait '.volume.percent == 125'

qst case "a picked clip is handed to wl-copy in a scope of its own, so a restart of the shell keeps it"
echo "a clip to pick" | cliphist store
qst ipc panels open clipboard > /dev/null
qst wait '.panel == "clipboard"'
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'systemd-run.*--scope.*wl-copy' || { qst actions; echo "the clip was not handed over in a scope"; exit 1; }

for screen in "1024x600 1" "1920x1080 3"; do
  read -r mode scale <<< "$screen"
  qst case "every panel fits a $mode screen at scale $scale"
  qst output "$mode" "$scale"
  qst wait ".screens[0].width <= ${mode%x*} / $scale + 1"
  for panel in apps clipboard monitors windows nixpkgs center:DP-1 shortcuts power controls:DP-1; do
    qst ipc panels open "$panel" > /dev/null
    qst wait ".panel == \"$panel\""
    qst stays ".panel == \"$panel\"" 0.6
  done
done

qst case "Power Off takes a second press, and moving the selection disarms it"
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key p
qst stays '.panel == "power"' 0.5
qst actions | grep -q poweroff && { echo "one press powered off"; exit 1; }
qst key Left p
qst stays '.panel == "power"' 0.5
qst actions | grep -q poweroff && { echo "a press after moving powered off"; exit 1; }
qst key p
qst wait '.panel == ""'
qst actions | grep -q 'systemctl poweroff' || { echo "two presses did not power off"; exit 1; }

qst case "the keyboard reaches the power menu's buttons, and Enter confirms the one a click armed"
# Restart to Firmware is the last button, as the session's logind offers it.
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key Left Return
qst stays '.panel == "power"' 0.5
qst actions | grep -q firmware-setup && { echo "one press restarted to firmware"; exit 1; }
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'systemctl reboot --firmware-setup' || { qst actions; echo "Left and Enter twice did not restart to firmware"; exit 1; }
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
read -r x y < <(qst areas PowerMenu | awk -F'\t' '$6 == "true" { x = $1; y = $2 } END { print x, y }')
qst click left "$x" "$y"
qst stays '.panel == "power"' 0.3
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'lock-session' && { qst actions; echo "Enter after arming Restart to Firmware locked"; exit 1; }
[ "$(qst actions | grep -c 'firmware-setup')" = 2 ] || { qst actions; echo "Enter did not confirm the armed button"; exit 1; }

qst case "a key held in the power menu arms its action and never confirms it"
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst hold p 1500
qst stays '.panel == "power"' 0.5
qst key Escape
qst wait '.panel == ""'
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key Right Right Right Right
qst hold Return 1500
qst stays '.panel == "power"' 0.5
qst actions | grep -q poweroff && { qst actions; echo "a held key powered off"; exit 1; }
qst key Return
qst wait '.panel == ""'
qst actions | grep -q 'systemctl poweroff' || { qst actions; echo "a second press did not power off"; exit 1; }

qst case "arming another action gives it the whole five seconds"
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key o
qst stays '.panel == "power"' 3
qst key p
qst stays '.panel == "power"' 3
qst key p
qst wait '.panel == ""'
qst actions | grep -q 'systemctl poweroff' || { qst actions; echo "Power Off was disarmed with the time Log Out had left"; exit 1; }

qst case "the power menu's keys are the keycaps on its tiles: O twice logs out"
qst ipc panels open power > /dev/null
qst wait '.panel == "power"'
qst key o
qst key o
for _ in $(seq 20); do qst actions | grep -q 'hl.dsp.exit()' && break; sleep 0.1; done # sleep: the action reaches the fake hyprctl, outside the probe
qst actions | grep -q 'hl.dsp.exit()' || { qst actions; echo "O twice did not log out"; exit 1; }

qst case "a tooltip shows half a second after the pointer rests on an icon button, under it, and goes as the pointer leaves or presses"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
read -r x y _ < <(qst areas 'ControlsPanel' | grep 'header:lock')
qst pointer "$x" "$y"
qst pointer $((x + 1)) $((y + 1))
qst stays '.tooltip == null' 0.3
qst wait '.tooltip.text == "Lock" and .tooltip.screen == "DP-1" and (.layers | index("DP-1 quickshell:tooltip")) != null'
qst pointer 900 600
qst wait '.tooltip == null and (.layers | index("DP-1 quickshell:tooltip") | not)'
read -r x y _ < <(qst areas 'ControlsPanel' | grep 'mute:output')
qst pointer "$x" "$y"
qst pointer $((x + 1)) $((y + 1))
qst wait '.tooltip.text == "Mute"'
qst click
qst wait '.tooltip == null and .volume.muted'
qst stays '.tooltip == null' 0.8

qst case "every control on the bar names itself in a tooltip, but a workspace, whose number is its name"
qst tray > /dev/null
qst wait '.tray | length > 0'
hover() {
  qst pointer "$1" 17
  qst pointer $(($1 + 1)) 18
  qst wait ".tooltip.text == \"$2\""
  qst pointer 900 600
  qst wait '.tooltip == null'
}
read -r status _ < <(qst areas 'BarWindow' | awk -F'\t' '$6 == "true" { x = $1 } END { print x }')
read -r first _ < <(qst areas 'BarWindow' | awk -F'\t' '$6 == "true"' | sort -n | head -1)
qst pointer "$first" 17
qst pointer $((first + 1)) 18
qst stays '.tooltip == null' 0.8
hover 960 "Notifications and Calendar"
hover "$status" "Quick Settings"
# A tray item names itself once the tray is out.
qst pointer 1850 16
qst wait '.trays[0].shown'
qst stays '.trays[0].shown' 0.3
read -r item _ < <(qst areas BarWindow | awk -F'\t' '$1 > 1000 && $1 < 1840 && $5 == "true" && $6 == "false" && $2 < 32' | sort -n | head -1)
qst pointer "$item" 17
qst pointer $((item + 1)) 18
qst wait '.tooltip.text == "qs-test tray"'

qst case "a tooltip sits at its control on screen, also from a window off the screen's corner: the popups at the right edge, the center below the bar"
# Where the probe says the tooltip's control is, against where it is on screen; the pointer comes in from the left in steps, or a popup never sees it.
at() {
  qst pointer 900 "$2"
  for dx in 300 150 60 20 2; do qst pointer $(($1 - dx)) "$2"; done
  qst pointer "$1" "$2"
  qst wait ".tooltip.text == \"$3\" and (.tooltip.at[0] - $1 | fabs) <= 2 and (.tooltip.at[1] - $2 | fabs) <= 2"
}
notify-send -t 0 -a Chat "Hello" "there"
notify-send -t 0 -a Mail "Hello" "again"
qst wait '(.popups | length) == 2'
read -r x y _ < <(qst areas popup:close | sort -t'	' -k2 -n | head -1)
at "$x" "$y" Close
# Empty, the calendar's Previous Month is the first button from the left.
qst ipc notifications clear > /dev/null
qst wait '.notifications == 0'
qst ipc panels open center > /dev/null
qst wait '.panel == "center:DP-1"'
read -r x y _ < <(qst areas NotificationCenter | awk -F'\t' '$2 < 200 && $4 == "true" && $6 == "true"' | sort -n | head -1)
at "$x" "$y" "Previous Month"

qst case "the distro's logo does nothing: an arrow, no tooltip, and a click opens nothing"
qst pointer 20 16
qst pointer 21 17
qst cursor 21 17 arrow
qst stays '.tooltip == null and .tooltipPending == null' 1
qst click left 21 17
qst stays '.panel == ""' 0.5

qst case "a bar button lights under the pointer and goes dark once the panel it opened closes, however it closed"
qst pointer 300 700
qst pointer 960 16
qst wait '.hovered == ["BarWindow/Clock"]'
qst click
qst wait '.panel == "center:DP-1"'
qst pointer 300 700
qst click
qst wait '.panel == "" and .hovered == []'
qst stays '.hovered == []' 0.5
read -r x y _ < <(qst areas 'BarWindow/' | awk -F'\t' '$1 > 1800' | tail -1)
qst pointer "$x" "$y"
qst wait '.hovered == ["BarWindow/StatusButton"]'
qst click
qst wait '.panel == "controls:DP-1"'
qst pointer 300 700
qst key Escape
qst wait '.panel == "" and .hovered == []'
qst pointer 960 16
qst click
qst wait '.panel == "center:DP-1"'
qst pointer 960 16
qst click
qst wait '.panel == ""'
qst pointer 300 700
qst wait '.hovered == []'
qst stays '.hovered == []' 0.5

qst case "a drag on the volume let go far outside the centre leaves the level where it ended, the centre open and no hand closed"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
read -r x y <<< "$(qst area ControlsPanel:slider:output)"
qst drag "$x" "$y" -900 700 400
qst wait '.volume.percent == 0'
qst stays '.panel == "controls:DP-1" and .volume.percent == 0' 0.5
qst cursor 400 900 arrow > /dev/null

qst case "a status glyph back while it still fades out shows again"
qst ipc notifications setDnd true > /dev/null
qst wait '.status[0].opaque | index("dnd") != null'
# Both calls within the glyph's fade.
qst x sh -c 'shell=${XDG_CONFIG_HOME%/cfg}/shell; qs ipc -p "$shell" call notifications setDnd false && qs ipc -p "$shell" call notifications setDnd true'
qst wait '.dnd and (.status[0].opaque | index("dnd") != null)'
qst stays '.status[0].opaque | index("dnd") != null' 0.5

qst case "a process run again from its own exit gets a whole deadline: night light's second strength reaches a slow hyprsunset"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst click ControlsPanel:menu:night
qst wait '.controls.menu == "night" and .controls.night.present'
qst fail hyprctl slow 'hyprsunset*'
log="$QS_TEST_DIR/hyprsunset.log"
seen=$(wc -l < "$log")
qst click ControlsPanel:slider:night -100 0
qst wait '.controls.night.on'
first=$(qst state '.controls.night.temperature')
qst click ControlsPanel:slider:night 100 0
qst wait ".controls.night.temperature != $first"
second=$(qst state '.controls.night.temperature')
# Two slow runs, the second started from the first's exit: past the 5 s deadline of the first's start.
applied() { tail -n +$((seen + 1)) "$log" | grep -aq "Setting the temperature to ${second}K"; }
for _ in $(seq 100); do applied && break; sleep 0.1; done # sleep: hyprsunset is outside the probe
applied || { tail -n +$((seen + 1)) "$log" | grep -a "Setting the temperature"; echo "the second strength never reached hyprsunset"; exit 1; }

qst case "Space held on a switch flips it once, not with every repeat"
qst ipc panels open center:DP-1 > /dev/null
qst wait '.panel == "center:DP-1"'
qst key Tab
qst wait '.focused == "NotificationCenter/Switch:switch:dnd"'
qst hold space 2000
qst wait '.dnd and .dndFlips == 1'

qst case "the arrows reach every row of a long menu, down and back up through the rows it makes again as it scrolls"
qst network wifi many 40
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst ipc controls menu wifi > /dev/null
qst wait '.controls.menu == "wifi" and .controls.open.rows > 40' 10
top=$(qst state '.controls.open.first[0]')
for _ in $(seq 15); do [ "$(qst state .focused)" = '"ControlsPanel/QQuickTextInput"' ] && break; qst key Tab; done
qst key Down
qst wait ".focusedTitle == $top"
mapfile -t downs < <(yes Down | head -30)
mapfile -t ups < <(yes Up | head -30)
qst key "${downs[@]}"
qst wait ".focusedTitle != $top and .focused == \"ControlsPanel/ListRow\""
qst key "${ups[@]}"
qst wait ".focusedTitle == $top"
qst key Up
qst wait '.focused == "ControlsPanel/QQuickTextInput"'
