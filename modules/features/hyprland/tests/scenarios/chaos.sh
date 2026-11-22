export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# What a hostile or broken client can throw at the shell. Every wait also holds the shell to answering within 2 s.

# SCREEN's tray, revealed by the pointer at X on its bar's right end.
reveal() {
  qst pointer "$2" 16
  qst wait "(.trays | map(select(.screen == \"$1\")))[0].shown"
  # Until the strip has finished sliding out, so its cells hold still.
  qst stays "(.trays | map(select(.screen == \"$1\")))[0].shown" 0.3
}

# The Nth tray cell between LO and HI on the bars, as "x y": the hand-less areas left of a status button.
tray_cell() {
  qst areas BarWindow | awk -F'\t' -v lo="$2" -v hi="$3" '$1 > lo && $1 < hi && $5 == "true" && $6 == "false" && $2 < 32' | sort -n | sed -n "${1}p" | awk -F'\t' '{ print $1, $2 }'
}

# The open menu's rows, top to bottom: full width, so centred on the card, where the levels' and pills' areas are not.
menu_rows() {
  qst areas 'ControlsPanel' | awk -F'\t' '$2 > 60 && $2 < 1000 { print $1, $2 }' | sort -n -k2 | awk '{ n[$1]++; at[$1] = at[$1] " " $2 } END { for (x in n) if (n[x] > best) { best = n[x]; bx = x } print bx at[bx] }'
}

# The control centre's areas by name (pill:wifi, row:Pixel_7128), as "x y", on the screen given or DP-1.
named() {
  qst areas 'ControlsPanel' | awk -F'\t' -v name="$1" -v screen="${2:-DP-1}" '(screen == "DP-1") == ($1 < 1920) && index($3, ":" name) && substr($3, index($3, ":" name) + length(name) + 1, 1) ~ /^( |$)/ { print $1, $2; exit }'
}

press_named() {
  local x y
  read -r x y < <(named "$@")
  [ -n "$x" ] || { echo "no area named $1" >&2; exit 1; }
  qst click left "$x" "$y"
}

qst case "a flood of critical notifications keeps five popups, plays almost nothing, and one card counts what it turned away"
qst flood 3000 --urgency 2
qst wait '(.popups | length) == 5'
sounds=$(qst actions | grep -c '^pw-play' || true)
[ "$sounds" -le 3 ] || { echo "$sounds sounds for one flood"; exit 1; }
qst wait 'any(.history[]; .app == "Notifications" and (.summary | test("Notifications Dropped$")))' 10
qst stays '.notifications <= 105' 1

qst case "a flood from thousands of apps keeps the history bounded and the center quick to open"
# alone: the flood is timed against the 2 s the probe may take, which other sessions on the machine eat into
qst flood 3000 --apps 3000
# Slower than the door turns away, so the history fills past what it keeps.
qst flood 150 --apps 150 --app Slow --rate 25
qst wait '.notifications >= 100'
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
qst stays '.panel == "center"' 1

qst case "megabytes of text cost no more than a line"
qst flood 2 --apps 2 --summary 2000000 --body 10000000
qst wait '.notifications == 2 and all(.history[]; (.summary | length) < 600)'
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
qst stays '.panel == "center"' 1

qst case "an icon that is no picture gives way to the app's initial"
junk=$(mktemp -p "$QS_TEST_DIR")
head -c 4096 /dev/urandom > "$junk"
# As the app icon itself: notify-send -i sends a picture hint, which Quickshell drops when it cannot read it.
qst flood 1 --app Junk --icon "$junk"
notify-send -a Junk -h "string:image-path:$junk" "a picture of noise"
qst expect --may 'Error decoding'
qst wait '.notifications == 2'
qst stays '(.popups | length) == 2' 1

qst case "panels toggled faster than they open leave no window behind"
for _ in $(seq 30); do
  for panel in center shortcuts power apps; do qst ipc panels toggle "$panel" > /dev/null & done
  wait
done
qst ipc panels close > /dev/null
qst wait '.panel == ""'
qst stays '([.layers[] | select(test("quickshell:(center|shortcuts|power|launcher)$"))] | length) == 0' 1

qst case "a storm of hotplugs and mode changes under an open panel and popups"
qst ipc panels open center > /dev/null
for n in $(seq 12); do
  notify-send -t 0 -a "Storm $n" "while plugging"
  qst monitor remove DP-2
  qst monitor add DP-2 2560x1440 1.25
  if [ $((n % 2)) = 0 ]; then qst output 1280x720 1.5; else qst output 1920x1080 1; fi
done
qst wait '(.screens | length) == 2 and all(.screens[]; .monitor != null)' 10
qst wait '(.layers | map(select(endswith(" quickshell:bar"))) | length) == 2'

qst case "a workspace crowded past what Hyprland can tile still previews in the window switcher"
# alone: the shell takes over a second to answer the probe here even with the machine to itself
for n in $(seq 40); do qst spawn foot -a "crowd$n" sleep 600; done
qst wait '(.windows | length) == 40' 30
qst key super+Tab
qst wait '.panel == "windows"'
for _ in $(seq 45); do qst key Down; done
qst stays '.panel == "windows"' 1

qst case "sixty outputs scroll in the control centre's sound menu rather than running off the screen"
for n in $(seq 60); do
  qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=chaos$n node.description=\"Output $n\" media.class=Audio/Sink object.linger=true audio.position=[FL FR] }" > /dev/null
done
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1"'
qst stays '.panel == "controls:DP-1"' 1

qst case "forty apps recording fit in the status button and the centre's In use pill"
for n in $(seq 40); do qst spawn pw-record -P "{ application.name=Recorder$n }" /dev/null; done
qst wait '(.privacy.mic | length) == 40' 20
qst wait '.status[0].glyphs[0] == "Microphone"'
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst stays '(.privacy.mic | length) == 40 and .panel == "controls:DP-1"' 1

qst case "thirty tray items fit the strip on the bar short of the clock, on a 640x480 screen too"
qst tray add crowd 30
qst wait '(.tray | length) == 30' 10
reveal DP-1 1850
qst wait '.trays[0].scrolls'
qst stays '.trays[0].shown' 1
qst output 640x480 1
reveal DP-1 600
qst stays '.trays[0].shown' 1

qst case "the strip keeps tray items in the order they came as items come and go"
n=0
for name in a b c d e f; do
  qst tray add "$name"
  n=$((n + 1))
  qst wait "(.tray | length) == $n" 10
done
qst tray add crowd 40
qst wait '(.tray | length) == 46' 10
qst wait '.trays[0].items[0:4] == ["a", "b", "c", "d"]'
qst tray remove b
qst wait '.trays[0].items[0:4] == ["a", "c", "d", "e"]'
qst tray remove a
qst wait '.trays[0].items[0:4] == ["c", "d", "e", "f"]'
qst tray add b
qst wait '(.tray | length) == 45' 10
qst stays '.trays[0].items[0:4] == ["c", "d", "e", "f"] and .trays[0].items[-1] == "b"' 1

qst case "tray items churning under the revealed strip and a menu opened from it"
qst tray add held 20
qst tray add stay 40
qst wait '(.tray | length) == 60' 10
reveal DP-1 1850
read -r x y < <(tray_cell 1 1000 1840)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.panel == "tray-menu:DP-1" and .trayMenu != null'
# The item whose menu is open leaves: the menu goes.
qst tray remove held
qst wait '(.tray | length) == 40 and .trayMenu == null and .panel == ""' 10
for n in $(seq 30); do qst tray add "churn$n" 2; done
for n in $(seq 30); do qst tray remove "churn$n"; done
qst wait '(.tray | length) == 40' 20
reveal DP-1 1850
qst stays '.trays[0].shown' 1
qst tray remove stay
qst wait '(.tray | length) == 0 and (.trays[0].shown | not)' 10

qst case "two hundred tray items scroll in the strip under the hammered wheel, and their monitor going closes a menu"
qst tray add swarm 200
qst wait '(.tray | length) == 200' 20
qst focus DP-2
reveal DP-2 3898
read -r x y < <(tray_cell 3 3000 3880)
qst pointer "$x" "$y"
for n in $(seq 20); do qst wheel 5; qst wheel -2; done
qst wait '(.trays | map(select(.screen == "DP-2")))[0].offset > 0'
qst wheel 1000
qst stays '(.trays | map(select(.screen == "DP-2")))[0].shown' 0.5
read -r x y < <(tray_cell 2 3000 3880)
qst click right "$x" "$y"
qst wait '.panel == "tray-menu:DP-2" and .trayMenu != null'
qst monitor remove DP-2
qst wait '.panel == "" and .trayMenu == null'

qst case "keys hammered at a tray menu whose app rebuilds it every second, on a 640x480 screen"
qst tray
qst wait '.tray | length > 0'
reveal DP-1 1850
read -r x y < <(tray_cell 1 1000 1840)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu.path == []'
qst key Down
qst wait '.trayMenu.selected == "First item"'
qst key End Up
qst wait '.trayMenu.selected == "Settings"'
qst key Right
qst wait '.trayMenu.path == ["Settings"] and .trayMenu.selected == "Rebuild every second"'
qst key Return
qst wait '.panel == ""'
qst output 640x480 1
reveal DP-1 600
read -r x y < <(tray_cell 1 330 620)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst key Down
qst wait '.trayMenu.selected == "First item"'
qst key End Up Up
qst wait '.trayMenu.selected == "Networks"'
qst key Right
qst wait '.trayMenu.path == ["Networks"]'
for round in $(seq 8); do
  qst key Down Down Up Right Left Right Down Left Left Right Up Up Down End Home Down Right Left
done
qst wait '.trayMenu != null and .panel == "tray-menu:DP-1"'
qst key Escape
qst wait '.trayMenu == null and .panel == ""'

qst case "the item whose menu the keys hold leaves: the menu goes and nothing is left open"
qst tray add held
qst tray add stay 5
qst wait '(.tray | length) == 6' 10
reveal DP-1 1850
read -r x y < <(tray_cell 1 1000 1840)
qst pointer "$x" "$y"
qst click right "$x" "$y"
qst wait '.trayMenu != null'
qst key Down
qst wait '.trayMenu.selected == "Open held"'
qst pointer 900 600
qst tray remove held
qst wait '.trayMenu == null and .panel == "" and (.tray | length) == 5' 10

qst case "forty microphones, real and virtual, scroll in the control centre's sound menu with the outputs"
for n in $(seq 30); do
  qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=mic$n node.description=\"Mic $n\" media.class=Audio/Source object.linger=true audio.position=[MONO] }" > /dev/null
done
for n in $(seq 10); do
  qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=vmic$n node.description=\"Virtual $n\" media.class=Audio/Source/Virtual object.linger=true audio.position=[MONO] }" > /dev/null
done
for n in $(seq 30); do
  qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=out$n node.description=\"Output $n\" media.class=Audio/Sink object.linger=true audio.position=[FL FR] }" > /dev/null
done
qst wait '(.microphone.inputs | length) == 43' 10
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1"'
read -r _ ys < <(menu_rows)
read -ra rows <<< "$ys"
# The list scrolls in what the screen leaves: some of its rows are on screen.
[ "${#rows[@]}" -gt 6 ] && [ "${#rows[@]}" -lt 40 ] || { echo "${#rows[@]} device rows on screen"; exit 1; }
qst pointer 960 "${rows[-1]}"
qst wheel 40
qst stays '.panel == "controls:DP-1"' 1

qst case "the default input switched as fast as clicks and wpctl go, the last pick holding"
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1"'
# The one in use comes first, so each pick moves the list: each row is found again by name.
for n in $(seq 0 29); do
  read -r x y < <(named "$([ $((n % 2)) -eq 0 ] && echo Headset || echo Microphone)")
  qst click left "$x" "$y"
done
qst wait '.microphone.input != null' 10
qst stays '.panel == "controls:DP-1" and (.microphone.inputs | length) == 3' 1
qst x wpctl set-default "$(qst x pw-dump | jq '.[] | select(.info.props."node.name" == "test-headset-mic") | .id')"
qst wait '.microphone.input == "Headset Microphone"'
ids=$(qst x pw-dump | jq -r '.[] | select(.info.props."media.class" // "" | test("^Audio/Source")) | .id')
for _ in 1 2 3 4 5; do for id in $ids; do qst x wpctl set-default "$id"; done; done
last=$(tail -1 <<< "$ids")
qst wait ".microphone.input == $(qst x pw-dump | jq ".[] | select(.id == $last) | .info.props.\"node.description\"")" 10
qst stays '.panel == "controls:DP-1"' 1

qst case "inputs coming and going under the open sound menu, the default among them"
qst x wpctl set-default "$(qst x pw-dump | jq '.[] | select(.info.props."node.name" == "test-headset-mic") | .id')"
qst wait '.microphone.input == "Headset Microphone"'
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1"'
for _ in 1 2 3; do
  for n in $(seq 15); do
    qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=come$n node.description=\"Coming $n\" media.class=Audio/Source object.linger=true audio.position=[MONO] }" > /dev/null
  done
  qst wait '(.microphone.inputs | length) == 18' 10
  for n in $(seq 15); do qst x pw-cli destroy "come$n" > /dev/null; done
  qst wait '(.microphone.inputs | length) == 3' 10
done
# The default itself goes: WirePlumber falls back to the next, and the list loses it.
qst x pw-cli destroy test-headset-mic > /dev/null
qst wait '.microphone.input == "Microphone" and .microphone.inputs == ["Microphone", "Noise Cancelling"]'
qst stays '.panel == "controls:DP-1"' 1

qst case "PipeWire restarting under the open sound menu brings the inputs back"
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1"'
qst pipewire restart
qst wait '(.microphone.inputs | length) == 3 and .microphone.input == "Microphone"' 15

qst case "state files damaged or edited by hand read as nothing"
state=$(dirname "$(qst state .historyFile | jq -r .)")
mkdir -p "$state"
echo '{"ranks":null}' > "$state/launcher.json"
echo '{"names":"DP-1"}' > "$state/monitors.json"
echo '[]' > "$state/notifications.json"
qst restart > /dev/null
qst expect 'Failed to deserialize json: not an object'
qst ipc panels open apps > /dev/null
qst wait '.panel == "apps"'
qst key Return
qst wait '.panel == ""'

qst case "the idle dim's calls in any order, hundreds at once, still end where the last left them"
idle_layers() { echo "(.layers | map(select(endswith(\" quickshell:idle\"))) | length) == $1"; }
calls=("fade 1 0.4" "fade 3 0.4" cancel hold locked unlocked)
for burst in $(seq 6); do
  for n in $(seq 30); do
    # shellcheck disable=SC2086
    qst ipc idle ${calls[RANDOM % ${#calls[@]}]} > /dev/null &
  done
  wait
done
qst ipc idle unlocked
qst wait "$(idle_layers 0)"
qst ipc idle fade 1 0.4
qst wait "$(idle_layers 2)"
qst ipc idle locked
qst wait "$(idle_layers 0)"

qst case "a burst of saved screenshots keeps three cards and no notify-send waiting for the rest"
picture=$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg
for n in $(seq 20); do
  notify-send -a Screenshot -n accessories-screenshot -i "file://$picture" -A default=Open -A open=Open -A "folder=Show in Folder" "Screenshot Saved" "~/Pictures/screenshots/$n.png" > /dev/null &
done
qst wait '(.history | length) >= 5' 10
qst ipc notifications hidePopups
qst wait '(.history | length) == 3 and (.popups | length) == 0' 10
# Each closed card ends its notify-send; only the three kept still wait for an action.
for _ in $(seq 50); do [ "$(jobs -pr | wc -l)" -le 3 ] && break; qst stays true 0.1; done
[ "$(jobs -pr | wc -l)" -le 3 ]
qst ipc notifications clear
wait

qst case "a run of copied screenshots is one card"
picture=$QS_TEST_REPO/modules/features/hyprland/tests/tray-icon.svg
for n in $(seq 30); do
  notify-send -a Screenshot -n accessories-screenshot -i "file://$picture" -h string:x-canonical-private-synchronous:screenshot "Screenshot Copied to Clipboard" "$n"
done
qst wait '(.history | length) == 1 and (.popups | length) == 1'
qst stays '(.history | length) == 1' 1

qst case "three hundred networks and hostile names: the list scrolls inside its menu and the filter finds one"
# alone: the shell takes over a second to answer the probe here even with the machine to itself
qst network wifi many 300 "Altibox "
qst network wifi json "$(jq -cn '[["Right‮to left", 90, "wpa2", "x"], ["two\nlines", 88, "open", ""], ["zero​width​", 86, "wpa2", "x"], [("A network a kilobyte long " * 40), 84, "wpa2", "x"], ["<b>bold</b> & co", 82, "open", ""]]')"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
press_named menu:wifi
qst wait '(.controls.network.networks | length) == 308' 15
rows=$(qst areas 'ControlsPanel' | grep -c ':row:' || true)
[ "$rows" -gt 3 ] && [ "$rows" -lt 40 ] || { echo "$rows rows on screen"; exit 1; }
read -r x y < <(qst areas 'ControlsPanel' | awk -F'\t' '$3 ~ /:row:/ { print $1, $2; exit }')
# The filter sits over the first row.
qst click left "$x" $((y - 38))
qst type "Altibox 17"
qst wait '.field == "Altibox 17"'
rows=$(qst areas 'ControlsPanel' | grep -c ':row:Altibox 17' || true)
[ "$rows" -ge 1 ] && [ "$rows" -le 11 ] || { echo "$rows rows match"; exit 1; }
qst stays '.panel == "controls:DP-1" and .controls.menu == "wifi"' 1

qst case "a thousand outputs: the one in use first, the rest behind a filter, and the centre still fits"
qst ipc bar fakeOutputs 1000 > /dev/null
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.menu == "sound" and .volume.output == "Output 601"'
first=$(qst areas 'ControlsPanel' | awk -F'\t' '$3 ~ /:row:/ { print $3; exit }')
[[ $first == *":row:Output 601"* ]] || { echo "first row: $first"; exit 1; }
qst stays '.panel == "controls:DP-1"' 1
# The header counts devices, not the Output and Input headings; a filter matching nothing says so, headings and all gone.
qst wait '.controls.open.count == 1003 and .controls.open.rows == 1005'
read -r x y < <(qst areas ControlsPanel | awk -F'\t' '$3 ~ /TextField$/ { print $1, $2; exit }')
qst click left "$x" "$y"
qst type zzzz
qst wait '.controls.open.rows == 0'
qst key ctrl+a BackSpace
qst type headset
qst wait '.controls.open.first == ["Input", "Headset Microphone"]'
qst ipc bar realVolume > /dev/null

qst case "fifty VPNs and a hundred Bluetooth devices scroll in their menus"
for n in $(seq 50); do qst network profile vpn "office-$n.vpn.example.org"; done
for n in $(seq 100); do qst bluetooth add "$(printf '11:22:33:44:%02X:%02X' $((n / 256)) $((n % 256)))" "Device $n $([ "$n" = 7 ] && printf 'with a name long enough to run off any row %.0s' 1 2 3 4 5)" audio-headset ok; done
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1" and (.controls.vpns | length) == 51'
press_named menu:vpn
qst stays '.controls.menu == "vpn"' 1
press_named menu:bluetooth
qst wait '(.controls.bluetooth.devices | length) == 100' 10
qst stays '.controls.menu == "bluetooth"' 1

qst case "NetworkManager restarting while a password is typed keeps the row and the menu"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
press_named menu:wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
press_named row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type half
qst network restart
qst wait '.controls.network.present and (.controls.network.networks | index("Hvit_Monster"))' 15
qst stays '.controls.network.asking == "Hvit_Monster" and .controls.menu == "wifi" and .panel == "controls:DP-1"' 1

qst case "the centre's monitor unplugged under an open menu closes it, and the other bar opens one of its own"
qst focus DP-2
qst ipc panels open controls:DP-2 > /dev/null
qst wait '.panel == "controls:DP-2"'
qst ipc controls menu bluetooth > /dev/null
qst monitor remove DP-2
qst wait '.panel == ""'
qst key super+a
qst wait '.panel == "controls:DP-1"'

qst case "toggles hammered faster than their services answer settle where the last click left them"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
for _ in $(seq 25); do press_named pill:wifi; done
qst wait '(.controls.network.wifiOn | not)' 10
for _ in $(seq 20); do press_named pill:night; done
qst wait '(.controls.night.on | not)'
for _ in $(seq 15); do press_named pill:vpn; done
# Each click reads the state before the last one is done, so only that it settles is certain.
qst wait '.controls.vpns[0].busy == null' 15
for _ in $(seq 21); do press_named pill:bluetooth; done
qst wait '(.controls.bluetooth.on | not)'
qst stays '.panel == "controls:DP-1"' 1

QS_TEST_SCALE=1.2 qst case "on a 1024x600 screen at the desktop's 1.2 the centre scrolls, and a password row scrolls into view"
qst output 1024x600 1
qst network wifi many 40
# At full strength it sorts first among the new ones, in view.
qst network wifi strength Hvit_Monster 100
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
qst ipc controls menu wifi > /dev/null
qst wait '(.controls.network.networks | length) == 43' 10
press_named row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type visible
qst wait '.field == "visible"'
qst stays '.panel == "controls:DP-1"' 1

QS_TEST_MONITORS="DP-1:3840x2160:2" QS_TEST_SCALE=1.2 qst case "on a 4K monitor at scale 2 with the shell at 1.2 the centre and its lists fit"
qst network wifi many 40
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
for menu in wifi output input bluetooth vpn night; do
  qst ipc controls menu "$menu" > /dev/null
  qst stays ".controls.menu == \"$menu\" and .panel == \"controls:DP-1\"" 0.6
done

qst case "a player skipping and pausing faster than the card draws keeps the length of the track it lands on, and the card moves on when it quits"
for n in 1 2 3 4 5; do qst player add "p$n" "Player $n" Paused; done
qst player add spotify Spotify
qst ipc panels open center > /dev/null
qst wait '.panel == "center" and .controls.media.identity == "Spotify"'
call() { dbus-send --session --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 "org.mpris.MediaPlayer2.Player.$1" > /dev/null; }
# Forty tracks on, a pause or play every second one: the last pause sent the third track's length, the last two skips dropped theirs.
for i in $(seq 40); do
  call Next
  [ $((i % 2)) -eq 1 ] || call PlayPause
done
qst wait '.controls.media.title == "Kid A" and .controls.media.playing'
qst stays '.controls.media.length == 284' 1
qst player remove spotify
qst wait '.controls.media.identity == "Player 1" and .controls.media.length == 251'

qst case "the volume hammered from the open centre and the input's mute from wpctl show the OSD at every change, ending on the last"
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu sound > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.menu == "sound" and .osdSettling == false'
read -r ox oy < <(named slider:output)
before=$(qst state .osdShown)
# Each round sets the volume somewhere new and flips the input's mute.
for i in $(seq 15); do
  qst click left $((ox - 100 + i * 12)) "$oy"
  wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
done
qst wait '.osd.kind == "microphone" and .osd.muted and .microphone.muted'
shows=$(($(qst state .osdShown) - before))
[ "$shows" -ge 20 ] || { echo "the OSD showed $shows times for 30 changes"; exit 1; }
for _ in $(seq 20); do wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; done
qst wait '.osd.kind == "volume" and .osd.muted == false and .volume.muted == false'
qst stays '.panel == "controls:DP-1"' 1

qst case "criticals arriving among twelve apps under the open center always lead their groups"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
for round in 1 2 3; do
  sleep 1 # sleep: past 30 a second the flood guard turns them away
  for app in $(seq 12); do
    notify-send -a "App $app" "note $round" &
    [ $(((app + round) % 3)) -ne 0 ] || notify-send -a "App $app" -u critical "alarm $round" &
  done
  wait
done
# Each app keeps its newest three; the list makes delegates only for the groups in view.
qst wait '.notifications == 36 and (.center | length) > 0' 10
qst stays '.center | all(.lines | map(.critical) | . == (sort | reverse))' 1
qst ipc notifications clear > /dev/null
qst wait '.notifications == 0'

qst case "the output's slider past 100 % dragged across while another app sets it further keeps one range per drag"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.5
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1" and (.sliders | map(select(.name == "slider:output"))[0].span * 100 | round) == 150'
read -r x y < <(named slider:output)
qst drag $((x - 140)) "$y" 280 0 600 &
for level in 1.6 1.8 2.0; do wpctl set-volume @DEFAULT_AUDIO_SINK@ "$level"; done
wait
# The drag ended at the far end of the range it began with, then the last level from outside stands or the drag's does.
qst wait '.volume.percent <= 200 and .volume.percent >= 100'
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.0
qst wait '.volume.percent == 200 and (.sliders | map(select(.name == "slider:output"))[0].span * 100 | round) == 200'
qst stays '.panel == "controls:DP-1"' 0.5

qst case "Escape pressed over and over through drags on the volume leaves it where each drag began"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1" and .volume.percent == 40'
read -r ox oy < <(named slider:output)
for _ in 1 2 3; do
  qst drag $((ox - 100)) "$oy" 200 0 900 &
  qst wait '.volume.percent != 40'
  qst key Escape
  wait
  qst drag $((ox + 100)) "$oy" -200 0 900 &
  qst wait '.volume.percent != 40'
  qst key Escape
  wait
done
qst wait '.volume.percent == 40'
qst stays '.panel == "controls:DP-1" and .volume.percent == 40' 0.6

qst case "words of garbage and slips typed as fast as keys go keep the launcher answering, and the last slip finds its app"
qst key super+d
qst wait '.panel == "apps"'
for word in qwxz zzzzzzzz fxfxfxfx aaaa firfeox thunderbrd gimpp fierfox; do
  qst key ctrl+a BackSpace
  qst type "$word"
done
qst wait '.field == "fierfox" and (.results | index("Firefox")) != null'
qst stays '.panel == "apps"' 0.5

qst case "Clear hammered while notifications keep arriving and the center closes and opens: every card ends in place or gone, and a last Clear takes all"
qst ipc panels open center > /dev/null
qst wait '.panel == "center"'
press() { read -r x y _ < <(qst areas 'NotificationCenter' | awk -F'\t' -v name=":$1" 'index($3, name) && $4 == "true" { print $1, $2; exit }'); [ -n "${x:-}" ] && qst click left "$x" "$y"; }
for n in $(seq 6); do notify-send -a "App $n" "first $n"; done
qst wait '.notifications == 6'
for round in $(seq 8); do
  press action:Clear || true
  notify-send -a Late "late $round" &
  notify-send -a "App $round" "again $round" &
  [ $((round % 3)) -eq 0 ] && { qst ipc panels close > /dev/null; qst ipc panels open center > /dev/null; }
done
wait
qst wait '.panel == "center" and (.history | map(select(.summary | startswith("first"))) | length) == 0'
qst wait '(.center | length) == ([.history[].app] | unique | length)'
qst stays '(.center | map(select(.slid != 0)) | length) == 0' 0.5
press action:Clear
qst wait '.notifications == 0 and (.center | length) == 0 and .panel == "center"'

qst case "the pointer swept over every button in the centre faster than the delay shows only the last one's tooltip, and the centre or its monitor going takes it away"
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
mapfile -t spots < <(qst areas 'ControlsPanel' | awk -F'\t' 'index($3, "header:") || index($3, "mute:") || index($3, "slider:") { print $1, $2 }')
for _ in 1 2 3; do
  for spot in "${spots[@]}"; do
    read -r x y <<< "$spot"
    qst pointer "$x" "$y"
  done
done
qst stays '.tooltip == null or .tooltip.text == "Unmute" or .tooltip.text == "Mute" or .tooltip.text == "Power Menu" or .tooltip.text == "Lock" or .tooltip.text == "Take Screenshot"' 0.2
read -r x y <<< "${spots[0]}"
qst pointer "$x" "$y"
qst pointer $((x + 1)) $((y + 1))
qst wait '.tooltip != null and .tooltip.screen == "DP-1"'
qst ipc panels close > /dev/null
qst wait '.tooltip == null and .panel == ""'
qst ipc panels open controls:DP-2 > /dev/null
qst wait '.panel == "controls:DP-2"'
read -r x y _ < <(qst areas 'ControlsPanel' | awk -F'\t' '$1 > 1920 && index($3, "header:lock")')
qst pointer "$x" "$y"
qst pointer $((x + 1)) $((y + 1))
qst wait '.tooltip.text == "Lock" and .tooltip.screen == "DP-2"'
qst monitor remove DP-2
qst wait '.tooltip == null' 5

qst case "hundreds of keys through the centre while networks come and go under it keep the focus inside, and Escape still closes"
qst ipc panels open controls:DP-1 > /dev/null
qst ipc controls menu wifi > /dev/null
qst wait '.panel == "controls:DP-1" and .controls.menu == "wifi"'
qst network wifi many 40 Churn > /dev/null
for round in $(seq 10); do
  qst key Tab Tab Down Down Down Up Tab shift+Tab Down Down
  [ $((round % 3)) -ne 0 ] || qst network wifi clear > /dev/null
  [ $((round % 3)) -ne 1 ] || qst network wifi many 30 "Round$round" > /dev/null
done
qst wait '.panel == "controls:DP-1"'
qst key Tab
qst wait '.focused != null and (.focused | startswith("ControlsPanel/"))'
qst key Escape
qst wait '.panel == ""'

qst case "pictures only the server holds, replaced by id faster than a frame and dismissed mid-grab, never crash the shell"
# A copy destroyed while Qt grabs it crashed the shell on the render thread (QQuickItemGrabResult::render).
replace() {
  gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "'Downloads'" "uint32 $1" "''" "'Download $2'" "'a picture from memory'" "@as []" \
    "{'image-data': <(2, 2, 8, true, 8, 4, [byte $(( $2 % 256 )), 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255])>}" "int32 -1" | tr -dc '0-9'
}
id=$(replace 0 0)
for n in $(seq 1 60); do replace "$id" "$n" > /dev/null & done
wait
for n in $(seq 1 40); do
  other=$(replace 0 "$n")
  qst ipc notifications clear > /dev/null &
  replace "$other" $((n + 100)) > /dev/null &
done
wait
qst stays 'true' 2
qst ipc notifications clear > /dev/null
qst wait '.notifications == 0'

qst case "tray items crossing three as they come and go keep the count true, the tray collapsed and gone when empty"
qst pointer 400 600
for _ in 1 2 3; do
  qst tray add churn 6
  qst wait '(.tray | length) == 6 and .trays[0].more == 3 and (.trays[0].expanded | not)' 10
  qst tray remove churn
  qst wait '(.tray | length) == 0 and (.trays[0].shown | not)' 10
done
qst tray add churn 2
qst wait '.trays[0].shown and .trays[0].more == 0 and (.trays[0].expanded | not)' 10
qst stays '.trays[0].more == 0' 0.5
