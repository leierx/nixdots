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
