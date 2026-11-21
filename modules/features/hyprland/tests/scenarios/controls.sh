export QS_TEST_MONITORS="DP-1:1920x1080:1"

# Where the area named NAME is (pill:wifi, menu:vpn, row:Pixel_7128), as "x y".
at() {
  qst areas 'ControlsPanel' | awk -F'\t' -v name="$1" 'index($3, ":" name) && substr($3, index($3, ":" name) + length(name) + 1, 1) ~ /^( |$)/ { print $1, $2; exit }'
}

press() {
  local x y
  read -r x y < <(at "$1")
  [ -n "$x" ] || { qst areas 'ControlsPanel' >&2; echo "no area named $1" >&2; exit 1; }
  qst click left "$x" "$y"
}

open() {
  qst ipc panels open controls:DP-1 > /dev/null
  qst wait '.panel == "controls:DP-1"'
  if [ -n "${1:-}" ]; then
    press "menu:$1"
    qst wait ".controls.menu == \"$1\""
  fi
}

# The bar's status button, the last on the bar that asks for a hand while there is no tray.
status_button() {
  qst areas 'BarWindow' | awk -F'\t' '$6 == "true" && $1 > 1500 { x = $1; y = $2 } END { print x, y }'
}

qst case "the bar's button, SUPER+A and Escape open and close the centre; the wheel is the volume's, and a right click does nothing"
read -r x y < <(status_button)
qst click left "$x" "$y"
qst wait '.panel == "controls:DP-1"'
qst key Escape
qst wait '.panel == ""'
qst key super+a
qst wait '.panel == "controls:DP-1"'
qst key super+a
qst wait '.panel == ""'
qst pointer "$x" "$y"
qst wheel -2
# Onto the 5 % marks: 64, 70, 75.
qst wait '.volume.percent == 75'
qst click right "$x" "$y"
qst stays '(.volume.muted | not) and .panel == ""' 0.5

qst case "every pill the machine has, and only those"
qst wait '[.controls.toggles[].key] == ["wired:enp8s0", "wifi", "vpn", "bluetooth", "night", "dnd"]' 10
qst bluetooth adapter remove
qst wait '[.controls.toggles[].key] == ["wired:enp8s0", "wifi", "vpn", "night", "dnd"]'
qst network device remove wlp5s0
qst network device remove enp8s0
qst wait '[.controls.toggles[].key] == ["vpn", "night", "dnd"]'

qst case "without NetworkManager one dim pill says so, and the pills come back with it"
open
qst network stop
qst wait '.controls.toggles[0] == { key: "network", subtitle: "Not available", on: false, unavailable: true }' 10
qst network start
qst wait '.controls.toggles[0].key == "wired:enp8s0" and (.controls.vpns | length) == 1' 10
qst stays '.panel == "controls:DP-1"' 0.5

QS_TEST_NETWORK=none QS_TEST_BLUETOOTH=none qst case "a machine with neither NetworkManager nor BlueZ"
qst expect 'Could not find an available backend'
qst expect 'DBusObjectManagerInterface for "org\.bluez"'
open
qst wait '[.controls.toggles[].key] == ["network", "night", "dnd"]'
read -r x y < <(at pill:network)
qst click left "$x" "$y"
qst stays '.controls.toggles[0].unavailable and .panel == "controls:DP-1"' 0.5

qst case "a saved network connects on a click, and disconnects on the next"
open wifi
qst wait '.controls.network.scanning and (.controls.network.networks | length) == 3'
press row:Pixel_7128
qst wait '.controls.network.connected == "Pixel_7128"'
press row:Pixel_7128
qst wait '.controls.network.connected == null'

qst case "a new secured network asks in its row: a wrong password asks again, the right one connects"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
press row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type wrong
qst key Return
qst wait '.controls.network.askError == "Wrong password" and (.controls.network.known | index("Hvit_Monster"))'
qst key ctrl+a
qst type monster
qst key Return
qst wait '.controls.network.connected == "Hvit_Monster" and .controls.network.asking == null and .controls.network.created == []'

qst case "giving up on a password that never worked takes the profile it left behind with it"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
press row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type wrong
qst key Return
qst wait '.controls.network.askError == "Wrong password"'
press row:Hvit_Monster
qst wait '.controls.network.asking == null and (.controls.network.known | index("Hvit_Monster") | not)'
qst x nmcli -t -f NAME connection show | grep -qx Hvit_Monster && { echo "the profile stayed"; exit 1; }
qst stays '.panel == "controls:DP-1"' 0.3

qst case "a network leaving while its password is typed keeps the row and what was typed"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
press row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type half
qst network wifi remove Hvit_Monster
qst wait '(.controls.network.networks | index("Hvit_Monster") | not) and .controls.network.asking == "Hvit_Monster"'
qst stays '.controls.network.asking == "Hvit_Monster"' 1

qst case "an open network connects at once; Wi-Fi off empties the list and turns the pill grey"
open wifi
qst wait '.controls.network.networks | index("Kaffebrenneriet Gjest")'
press "row:Kaffebrenneriet Gjest"
qst wait '.controls.network.connected == "Kaffebrenneriet Gjest"'
press pill:wifi
qst wait '(.controls.network.wifiOn | not) and .controls.network.networks == [] and (.controls.toggles | map(select(.key == "wifi"))[0].on | not)'
press pill:wifi
qst wait '.controls.network.wifiOn and (.controls.network.networks | length) == 3' 10

qst case "the hardware switch: the pill says so and takes no click"
open
qst network switch off
qst wait '.controls.toggles | map(select(.key == "wifi"))[0] | .unavailable and .subtitle == "Off by switch"'
press pill:wifi 2> /dev/null || true
qst stays '(.controls.network.wifiOn | not)' 0.5
qst network switch on
qst wait '.controls.network.wifiOn'

qst case "a captive portal: a notification and the connected row offer to sign in, which opens the browser"
qst network up Pixel_7128
qst wait '.controls.network.connected == "Pixel_7128"'
qst network connectivity portal
qst wait '.controls.network.portal and any(.history[]; .summary == "Sign In to Network")'
open wifi
qst wait '.controls.toggles | map(select(.key == "wifi"))[0].subtitle == "Sign in to network"'
press sign-in
qst wait '.panel == ""'
qst actions | grep -q 'xdg-open http://neverssl.com/' || { qst actions; echo "the portal was not opened"; exit 1; }
qst network connectivity full
qst wait '(.controls.network.portal | not)'
# Online again, its card goes with the portal.
qst wait 'all(.history[]; .summary != "Sign In to Network")'

qst case "a VPN goes down and up on a click, and the pill takes them all"
open vpn
press row:wg0
qst wait '.controls.vpns == [{ name: "wg0", active: false, busy: null }]'
press row:wg0
qst wait '.controls.vpns == [{ name: "wg0", active: true, busy: null }]' 10
press pill:vpn
qst wait '.controls.vpns[0].active | not'

qst case "a VPN wanting a password asks in its row, and comes up with it"
qst network profile vpn Office
qst network vpn Office secrets
open vpn
qst wait '(.controls.vpns | length) == 2'
press row:Office
qst wait '.controls.vpnAsking != null' 10
qst type hunter2
qst key Return
qst wait '.controls.vpns | map(select(.name == "Office"))[0].active' 10
qst actions | grep -q 'passwd-file /dev/stdin' || { qst actions; echo "the password did not go through passwd-file"; exit 1; }

qst case "a VPN that fails flips back and says why"
qst network profile vpn Broken
qst network vpn Broken fail
open vpn
qst wait '(.controls.vpns | length) == 2'
press row:Broken
qst wait 'any(.history[]; .summary == "Broken Failed to Connect")' 10
qst wait '.controls.vpns | map(select(.name == "Broken"))[0] | (.active | not) and .busy == null'

qst case "a new headset pairs, is trusted and connects in one click; a keyboard wanting a PIN says where to go"
qst bluetooth add 11:22:33:44:55:01 "WH-1000XM4" audio-headset ok
qst bluetooth add 11:22:33:44:55:02 "Keychron K3" input-keyboard pin
qst bluetooth add 11:22:33:44:55:03 ""
qst expect 'Failed to pair'
open bluetooth
qst wait '.controls.bluetooth.scanning and (.controls.bluetooth.devices | length) == 2'
press row:WH-1000XM4
qst wait '.controls.bluetooth.devices | map(select(.name == "WH-1000XM4"))[0] | .paired and .trusted and .connected'
press "row:Keychron K3"
qst wait '.controls.bluetooth.devices | map(select(.name == "Keychron K3"))[0].note == "Needs a PIN: use Bluetooth Settings"'
press row:WH-1000XM4
qst wait '.controls.bluetooth.devices | map(select(.name == "WH-1000XM4"))[0].connected | not'
qst ipc panels close > /dev/null
qst wait '(.controls.bluetooth.scanning | not)'

qst case "Bluetooth off says so in its menu, and Bluetooth Settings opens bluetui"
open bluetooth
press pill:bluetooth
qst wait '(.controls.bluetooth.on | not)'
press "action:Bluetooth Settings"
qst wait '.panel == ""'
qst actions | grep -q 'systemd-run.*bluetui' || { qst actions; echo "bluetui was not opened"; exit 1; }

qst case "night light: hyprsunset gets the strength, and the shell keeps it through a restart"
open
press pill:night
qst wait '.controls.night.on'
qst wait '.controls.night.present'
[ "$(qst x hyprctl hyprsunset temperature)" = 4000 ] || { echo "hyprsunset is at $(qst x hyprctl hyprsunset temperature)"; exit 1; }
qst restart > /dev/null
qst wait '.controls.night.on and .controls.night.temperature == 4000'
qst x hyprctl hyprsunset identity > /dev/null
qst x hyprctl hyprsunset temperature 6000 > /dev/null
# hyprsunset started again reads its own default; the shell looks every ten seconds.
for _ in $(seq 120); do [ "$(qst x hyprctl hyprsunset temperature)" = 4000 ] && break; sleep 0.1; done # sleep: hyprsunset is outside the probe
[ "$(qst x hyprctl hyprsunset temperature)" = 4000 ] || { echo "the tint was not put back"; exit 1; }
open
press pill:night
qst wait '(.controls.night.on | not)'

qst case "night light's strength is in its pill's menu, and moving it turns night light on"
open night
qst wait '.controls.night.present and (.controls.night.on | not)'
read -r x y < <(at slider:night)
qst click left $((x + 80)) "$y"
qst wait '.controls.night.on and .controls.night.temperature < 4000'
for _ in $(seq 50); do [ "$(qst x hyprctl hyprsunset temperature)" -lt 4000 ] && break; sleep 0.1; done # sleep: hyprsunset is outside the probe
[ "$(qst x hyprctl hyprsunset temperature)" -lt 4000 ] || { echo "hyprsunset is at $(qst x hyprctl hyprsunset temperature)"; exit 1; }
press menu:night
qst wait '.controls.menu == ""'

qst case "a backlight gets a slider, set through brightnessctl, and the OSD shows the level it sets"
qst backlight intel_backlight 600 1000
open
qst wait '.brightness.intel_backlight.brightness == 600'
read -r x y < <(qst areas 'ControlsPanel' | awk -F'\t' '{ print $1, $2 }' | sort -n -k2 | awk '{ count[$2]++; if (!($2 in x)) x[$2] = $1 } END { for (y in count) if (count[y] == 2) print x[y], y }' | sort -n -k2 | head -1)
qst click left $((x + 40)) "$y"
qst wait '.brightness.intel_backlight.brightness < 600'
qst wait '.osd.kind == "brightness" and .osd.level < 0.6'
qst actions | grep -q 'brightnessctl --quiet --device intel_backlight set' || { qst actions; echo "brightnessctl was not run"; exit 1; }

qst case "the centre's own levels and mute buttons show the OSD with the level they set"
open
qst wait '.osdSettling == false'
read -r x y < <(at slider:output)
qst click left $((x - 60)) "$y"
qst wait '.osd.kind == "volume" and .osd.level < 0.6 and .osd.screen == "DP-1"'
press mute:input
qst wait '.osd.kind == "microphone" and .osd.muted'
read -r x y < <(at slider:input)
qst click left $((x - 60)) "$y"
qst wait '.osd.kind == "microphone" and .osd.muted == false and .osd.level < 0.6'

qst case "the player that played last gets the card; stopped, it goes"
# alone: removing a playing player races Quickshell polling its position, and a loaded machine widens the race
# The race can lose the poll's reply as the player leaves the bus.
qst expect --may 'Error updating property org.mpris.MediaPlayer2.firefox'
qst expect --may 'Message recipient disconnected from message bus without replying'
qst player add spotify Spotify Playing
qst player add firefox Firefox Paused
open
qst wait '.controls.media.identity == "Spotify" and .controls.media.playing'
qst player status spotify Paused
qst player status firefox Playing
qst wait '.controls.media.identity == "Firefox"'
qst player remove firefox
qst wait '.controls.media.identity == "Spotify"'
qst player status spotify Stopped
qst wait '.controls.media == null'

qst case "the sound menus: the output picked from the list, the one in use first"
open
qst ipc controls menu output > /dev/null
qst wait '.controls.menu == "output"'
press row:Headphones
qst wait '.volume.output == "Headphones"'
qst stays '.panel == "controls:DP-1" and .controls.menu == "output"' 0.5

qst case "PipeWire gone: one dim line where the sliders were, and back when it is"
open
qst pipewire stop
qst wait '.volume.output == null'
qst pipewire start
qst wait '.volume.output == "Speakers"' 15

qst case "the status button: what records first, the bell while notifications wait, Do Not Disturb struck through, the battery last"
qst wait '.status[0].glyphs == ["vpn", "network", "volume"] and .status[0].battery == 76'
notify-send -a Chat "hello"
qst wait '.status[0].glyphs[0] == "bell"'
qst spawn pw-record -P "{ application.name=Recorder }" /dev/null
qst wait '.status[0].glyphs[0:2] == ["Microphone", "bell"]'
qst ipc notifications setDnd true > /dev/null
qst wait '.status[0].glyphs[0:2] == ["Microphone", "dnd"]'
qst battery remove
qst wait '.status[0].battery == null'

qst case "the header: a screenshot and the lock close the centre first, power opens the power menu"
open
press header:screenshot
qst wait '.panel == ""'
for _ in $(seq 30); do qst actions | grep -q 'freeze-region copy' && break; sleep 0.1; done # sleep: the screenshot waits out the centre's fade, which the probe does not see
qst actions | grep -qx 'systemd-run --user --scope --quiet freeze-region copy'
open
press header:lock
qst wait '.panel == ""'
qst actions | grep -qx 'loginctl lock-session'
open
press header:power
qst wait '.panel == "power"'

qst case "what records gets an In use pill naming the app, which raises its window"
qst spawn foot
qst wait '.windows | length == 1'
qst spawn pw-record -P "{ application.name=foot }" /dev/null
qst wait '.privacy.mic == ["foot"]'
open
for _ in $(seq 30); do qst areas 'ControlsPanel' | grep -q "inuse:Microphone	true" && break; sleep 0.1; done # sleep: the window list reaches the pill through wlr-foreign-toplevel, outside the probe
press inuse:Microphone
qst wait '.panel == ""'

qst case "a Bluetooth device's charge and link are drawn in its row"
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70
qst wait '.controls.bluetooth.devices[0].battery == 70'
open bluetooth
[ -n "$(at row:Headset)" ]

qst case "the player's progress shows where the track is as the centre opens, and seeks where it is clicked"
qst player add spotify Spotify
open
qst wait '.controls.media.position >= 96 and .controls.media.position < 110 and .controls.media.length == 251'
read -r x y < <(at slider:media)
qst click left "$x" "$y"
qst wait '.controls.media.position > 115 and .controls.media.position < 140'

qst case "a length the player drops from a new track's metadata as it plays stays on the card, as Firefox drops it on YouTube"
qst player add spotify Spotify
open
qst wait '.controls.media.length == 251'
dbus-send --session --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next > /dev/null
qst wait '.controls.media.title == "Kid A"'
qst stays '.controls.media.length == 284' 1
[ -n "$(at slider:media)" ]

qst case "past 100 % the output's slider reaches as far as the level, marks 100 %, and a click sets a share of that range"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.3
qst wait '.volume.percent == 130'
open
qst wait '(.sliders | map(select(.name == "slider:output"))[0].span * 100 | round) == 130'
read -r x y < <(at slider:output)
qst click left "$x" "$y"
qst wait '.volume.percent == 65'
qst stays '.volume.percent == 65' 0.5

qst case "Escape mid-drag puts the level back where the drag began and keeps the centre open; Escape after closes it"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4
open
qst wait '.volume.percent == 40'
read -r x y < <(at slider:output)
qst drag $((x - 60)) "$y" 180 0 2500 &
qst wait '.volume.percent > 50'
qst key Escape
wait
qst wait '.volume.percent == 40'
qst stays '.panel == "controls:DP-1" and .volume.percent == 40' 0.6
qst key Escape
qst wait '.panel == ""'

qst case "the keyboard reaches every control in the centre: Tab and the arrows move a ring, Space toggles a pill, Return opens its menu, the arrows step a slider"
open
qst stays '.ring == false' 0.3
qst key Tab
qst wait '.focused == "ControlsPanel/IconButton:header:screenshot" and .ring'
qst key Down Down Down Down
qst wait '.focused == "ControlsPanel/Slider:slider:output"'
qst key Right Right
qst wait '.volume.percent == 75'
qst key Left
qst wait '.volume.percent == 70'
# On to the first pill, Wired, past the output's arrow and the input's mute, slider and arrow.
qst key Tab Tab Tab Tab Tab
qst wait '.focused == "ControlsPanel/Pill"'
qst key space
qst wait '.controls.toggles[0].on == false'
qst key Tab
qst key Return
qst wait '.controls.menu == "wifi"'
qst key Escape
qst wait '.panel == ""'
