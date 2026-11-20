export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:2560x1440:1.25"

# What a hostile or broken client can throw at the shell. Every wait also holds the shell to answering within 2 s.

qst case "a flood of critical notifications keeps five popups, plays almost nothing, and one card counts what it turned away"
qst flood 3000 --urgency 2
qst wait '(.popups | length) == 5'
sounds=$(qst actions | grep -c '^pw-play' || true)
[ "$sounds" -le 3 ] || { echo "$sounds sounds for one flood"; exit 1; }
qst wait 'any(.history[]; .app == "Notifications" and (.summary | test("notifications dropped$")))' 10
qst stays '.notifications <= 105' 1

qst case "a flood from thousands of apps keeps the history bounded and the center quick to open"
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
for n in $(seq 40); do qst spawn foot -a "crowd$n" sleep 600; done
qst wait '(.windows | length) == 40' 30
qst key super+Tab
qst wait '.panel == "windows"'
for _ in $(seq 45); do qst key Down; done
qst stays '.panel == "windows"' 1

qst case "sixty outputs scroll in the volume popup rather than running off the screen"
for n in $(seq 60); do
  qst x pw-cli create-node adapter "{ factory.name=support.null-audio-sink node.name=chaos$n node.description=\"Output $n\" media.class=Audio/Sink object.linger=true audio.position=[FL FR] }" > /dev/null
done
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
qst stays '.panel == "volume:DP-1"' 1

qst case "forty apps recording fit under the privacy indicator"
for n in $(seq 40); do qst spawn pw-record -P "{ application.name=Recorder$n }" /dev/null; done
qst wait '(.privacy.mic | length) == 40' 20
read -r x y _ < <(qst areas 'BarWindow/PrivacyIndicator' | head -1)
qst pointer "$x" "$y"
qst pointer $((x + 1)) "$y"
qst wait '.layers | any(endswith(" quickshell:privacy"))'
qst stays '(.privacy.mic | length) == 40' 1

# The tray's button closes its pill, the last area on a bar that asks for a hand; DP-1's bar ends at 1920.
tray_button() {
  qst areas 'BarWindow' | awk -F'\t' -v screen="$1" '(screen == "DP-1") == ($1 < 1920) && $6 == "true" { x = $1; y = $2 } END { print x, y }'
}

# The popup's device rows, top to bottom: full width, so centred on the card, where the level's mute and slider are not.
volume_rows() {
  qst areas 'VolumePopup' | awk -F'\t' '$2 > 60 && $2 < 1000 { print $1, $2 }' | sort -n -k2 | awk '{ n[$1]++; at[$1] = at[$1] " " $2 } END { for (x in n) if (n[x] > best) { best = n[x]; bx = x } print bx at[bx] }'
}

qst case "thirty tray items keep the bar off the clock: the first four stay, the rest wait behind its button"
for n in 1 2 3 4; do
  qst tray add "first$n"
  qst wait "(.tray | length) == $n" 10
done
qst tray add crowd 26
qst wait '(.tray | length) == 30' 10
qst wait 'all(.trays[]; .shown == ["first1", "first2", "first3", "first4"] and .hidden == 26 and .width <= .room)'
read -r x y < <(tray_button DP-1)
qst click left "$x" "$y"
qst wait '.panel == "tray-overflow:DP-1"'
qst stays '.panel == "tray-overflow:DP-1"' 1
# A narrow screen keeps fewer rather than reaching the clock.
qst output 800x600 1
qst wait 'any(.trays[]; .screen == "DP-1" and (.shown | length) < 4 and (.shown | length) + .hidden == 30 and .width <= .room)'

qst case "the first tray items keep their places as items come and go"
n=0
for name in a b c d e f; do
  qst tray add "$name"
  n=$((n + 1))
  qst wait "(.tray | length) == $n" 10
done
qst tray add crowd 20
qst wait '(.tray | length) == 26' 10
qst wait '.trays[0].shown == ["a", "b", "c", "d"]'
qst tray remove b
qst wait '.trays[0].shown == ["a", "c", "d", "e"]'
qst tray remove a
qst wait '.trays[0].shown == ["c", "d", "e", "f"]'
qst tray add b
qst wait '(.tray | length) == 25' 10
qst stays '.trays[0].shown == ["c", "d", "e", "f"]' 1

qst case "tray items churning under the open overflow and a menu opened from it"
qst tray add held 20
qst tray add stay 40
qst wait '(.tray | length) == 60' 10
read -r x y < <(tray_button DP-1)
qst click left "$x" "$y"
qst wait '.panel == "tray-overflow:DP-1"'
read -r cx cy _ < <(qst areas 'TrayOverflow' | awk -F'\t' '$2 > 60 && $2 < 1000' | sort -n -k2 | head -1)
qst click right "$cx" "$cy"
qst wait '.layers | any(endswith(" quickshell:menu"))'
# The item whose menu is open leaves: the menu goes, the overflow stays.
qst tray remove held
qst wait '(.tray | length) == 40 and .panel == "tray-overflow:DP-1" and (.layers | any(endswith(" quickshell:menu")) | not)' 10
for n in $(seq 30); do qst tray add "churn$n" 2; done
for n in $(seq 30); do qst tray remove "churn$n"; done
qst wait '(.tray | length) == 40' 20
qst stays '.panel == "tray-overflow:DP-1"' 1
# Nothing left behind the button closes the overflow.
qst tray remove stay
qst wait '.panel == "" and (.tray | length) == 0' 10

qst case "two hundred tray items scroll in the overflow rather than running off the screen"
qst tray add swarm 200
qst wait '(.tray | length) == 200' 20
qst wait 'all(.trays[]; .hidden == 196)' 10
read -r x y < <(tray_button DP-2)
qst focus DP-2
qst click left "$x" "$y"
qst wait '.panel == "tray-overflow:DP-2"'
qst wheel 20
qst stays '.panel == "tray-overflow:DP-2"' 1
# Its monitor going closes it.
qst monitor remove DP-2
qst wait '.panel == ""'

qst case "forty microphones, real and virtual, scroll in the volume popup with the outputs"
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
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
read -r _ ys < <(volume_rows)
read -ra rows <<< "$ys"
# Both lists scroll in what the screen leaves: some rows of each are on screen.
[ "${#rows[@]}" -gt 6 ] && [ "${#rows[@]}" -lt 40 ] || { echo "${#rows[@]} device rows on screen"; exit 1; }
qst pointer 960 "${rows[-1]}"
qst wheel 40
qst stays '.panel == "volume:DP-1"' 1

qst case "the default input switched as fast as clicks and wpctl go, the last pick holding"
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
read -r x ys < <(volume_rows)
read -ra rows <<< "$ys"
# Outputs first: Speakers, Headphones, HDMI; then Microphone, Headset Microphone, Noise Cancelling (virtual, through wpctl).
names=("Microphone" "Headset Microphone" "Noise Cancelling")
for n in $(seq 0 29); do qst click left "$x" "${rows[$((3 + n % 3))]}"; done
qst wait ".microphone.input == \"${names[2]}\"" 10
qst stays ".microphone.input == \"${names[2]}\" and .panel == \"volume:DP-1\"" 1
qst click left "$x" "${rows[4]}"
qst wait '.microphone.input == "Headset Microphone" and .microphone.adjustable'
ids=$(qst x pw-dump | jq -r '.[] | select(.info.props."media.class" // "" | test("^Audio/Source")) | .id')
for _ in 1 2 3 4 5; do for id in $ids; do qst x wpctl set-default "$id"; done; done
last=$(tail -1 <<< "$ids")
qst wait ".microphone.input == $(qst x pw-dump | jq ".[] | select(.id == $last) | .info.props.\"node.description\"")" 10
qst stays '.panel == "volume:DP-1"' 1

qst case "inputs coming and going under the open popup, the default among them"
qst x wpctl set-default "$(qst x pw-dump | jq '.[] | select(.info.props."node.name" == "test-headset-mic") | .id')"
qst wait '.microphone.input == "Headset Microphone"'
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
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
qst stays '.panel == "volume:DP-1"' 1

qst case "the microphone's mute and level hammered from the popup"
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
# A level row is the y with two areas, its mute and its slider; the output's first, the input's second.
read -r mx my < <(qst areas 'VolumePopup' | awk -F'\t' '$2 > 60 { print $1, $2 }' | sort -n -k2 -k1 | awk '{ count[$2]++; if (!($2 in x)) x[$2] = $1 } END { for (y in count) if (count[y] == 2) print x[y], y }' | sort -n -k2 | sed -n 2p)
for _ in $(seq 20); do qst click left "$mx" "$my"; done
qst wait '.microphone.muted | not'
qst stays '.microphone.muted | not' 0.5
qst pointer $((mx + 120)) "$my"
qst wheel 30
qst wait '.microphone.percent == 0'
qst wheel -40
qst wait '.microphone.percent == 100 and (.microphone.muted | not)'
qst stays '.microphone.percent == 100 and .panel == "volume:DP-1"' 1

qst case "PipeWire restarting under the open popup brings the inputs back"
qst ipc panels open volume:DP-1 > /dev/null
qst wait '.panel == "volume:DP-1"'
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
