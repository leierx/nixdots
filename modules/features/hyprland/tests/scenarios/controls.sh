export QS_TEST_MONITORS="DP-1:1920x1080:1"

open() {
  qst ipc panels open controls:DP-1 > /dev/null
  qst wait '.panel == "controls:DP-1"'
  if [ -n "${1:-}" ]; then
    qst click "ControlsPanel:menu:$1"
    qst wait ".controls.menu == \"$1\""
  fi
}

# The center, where the player's card is.
center() {
  qst ipc panels open center > /dev/null
  qst wait '.panel == "center"'
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
qst wait '[.controls.toggles[].key] == ["wired:enp8s0", "wifi", "vpn", "bluetooth", "night", "caffeine"]' 10
qst bluetooth adapter remove
qst wait '[.controls.toggles[].key] == ["wired:enp8s0", "wifi", "vpn", "night", "caffeine"]'
qst network device remove wlp5s0
qst network device remove enp8s0
qst wait '[.controls.toggles[].key] == ["vpn", "night", "caffeine"]'

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
qst wait '[.controls.toggles[].key] == ["network", "night", "caffeine"]'
qst click ControlsPanel:pill:network
qst stays '.controls.toggles[0].unavailable and .panel == "controls:DP-1"' 0.5

qst case "a saved network connects on a click, and disconnects on the next"
open wifi
qst wait '.controls.network.scanning and (.controls.network.networks | length) == 3'
qst click ControlsPanel:row:Pixel_7128
qst wait '.controls.network.connected == "Pixel_7128"'
qst click ControlsPanel:row:Pixel_7128
qst wait '.controls.network.connected == null'

qst case "a new secured network asks in its row: a wrong password asks again, the right one connects"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
qst click ControlsPanel:row:Hvit_Monster
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
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type wrong
qst key Return
qst wait '.controls.network.askError == "Wrong password"'
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == null and (.controls.network.known | index("Hvit_Monster") | not)'
qst x nmcli -t -f NAME connection show | grep -qx Hvit_Monster && { echo "the profile stayed"; exit 1; }
qst stays '.panel == "controls:DP-1"' 0.3

qst case "the centre shut while a new network's password is tried keeps the profile it connects with"
qst network delay 1500
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type monster
qst key Return
qst key Escape Escape
qst wait '.panel == ""'
qst wait '.controls.network.connected == "Hvit_Monster" and (.controls.network.known | index("Hvit_Monster")) and .controls.network.created == []' 10

qst case "the centre shut while a wrong password is tried takes the profile with it, and the row says why"
qst network delay 1500
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type wrong
qst key Return
qst key Escape Escape
qst wait '.panel == ""'
qst wait '.controls.network.failures.Hvit_Monster == "Wrong password" and (.controls.network.known | index("Hvit_Monster") | not) and .controls.network.created == [] and .controls.network.asking == null' 10

qst case "Left and Right in a password field move its cursor, not the keyboard's place in the centre"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type ab
qst key Right Left Left Left
qst type x
qst wait '.field == "xab"'

qst case "a network leaving while its password is typed keeps the row and what was typed"
open wifi
qst wait '.controls.network.networks | index("Hvit_Monster")'
qst click ControlsPanel:row:Hvit_Monster
qst wait '.controls.network.asking == "Hvit_Monster"'
qst type half
qst network wifi remove Hvit_Monster
qst wait '(.controls.network.networks | index("Hvit_Monster") | not) and .controls.network.asking == "Hvit_Monster"'
qst stays '.controls.network.asking == "Hvit_Monster"' 1

qst case "an open network connects at once; Wi-Fi off empties the list and turns the pill grey"
open wifi
qst wait '.controls.network.networks | index("Kaffebrenneriet Gjest")'
qst click "ControlsPanel:row:Kaffebrenneriet Gjest"
qst wait '.controls.network.connected == "Kaffebrenneriet Gjest"'
qst click ControlsPanel:pill:wifi
qst wait '(.controls.network.wifiOn | not) and .controls.network.networks == [] and (.controls.toggles | map(select(.key == "wifi"))[0].on | not)'
qst click ControlsPanel:pill:wifi
qst wait '.controls.network.wifiOn and (.controls.network.networks | length) == 3' 10

qst case "the hardware switch: the pill says so and takes no click"
open
qst network switch off
qst wait '.controls.toggles | map(select(.key == "wifi"))[0] | .unavailable and .subtitle == "Off by switch"'
qst click ControlsPanel:pill:wifi 2> /dev/null || true
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
qst click ControlsPanel:sign-in
qst wait '.panel == ""'
qst actions | grep -q 'xdg-open http://neverssl.com/' || { qst actions; echo "the portal was not opened"; exit 1; }
qst network connectivity full
qst wait '(.controls.network.portal | not)'
# Online again, its card goes with the portal.
qst wait 'all(.history[]; .summary != "Sign In to Network")'

qst case "a portal blocking DNS over TLS reads as no internet: Sign In takes the network's own DNS for the connection, the profile's again once online"
qst network up Pixel_7128
qst wait '.controls.network.connected == "Pixel_7128"'
qst network connectivity limited
open wifi
qst wait '.controls.network.signIn'
qst click ControlsPanel:sign-in
qst wait '.panel == "" and .controls.network.relaxed != null'
qst actions | grep -q 'nmcli device modify .* ipv4.ignore-auto-dns no .* connection.dns-over-tls no' || { qst actions; echo "the connection kept its DNS"; exit 1; }
qst actions | grep -q 'xdg-open http://neverssl.com/' || { qst actions; echo "the portal was not opened"; exit 1; }
# Resolving now, it shows as the portal it is; the browser is on it already, so no card.
qst network connectivity portal
qst stays 'all(.history[]; .summary != "Sign In to Network")' 1
qst network connectivity full
qst wait '.controls.network.relaxed == null'
qst actions | grep -q 'nmcli device reapply' || { qst actions; echo "the profile's DNS was not put back"; exit 1; }

qst case "a shell restarted mid-sign-in still puts the profile's DNS back once online"
qst network up Pixel_7128
qst wait '.controls.network.connected == "Pixel_7128"'
qst network connectivity limited
open wifi
qst wait '.controls.network.signIn'
qst click ControlsPanel:sign-in
qst wait '.panel == "" and .controls.network.relaxed != null'
qst restart > /dev/null
qst wait '.controls.network.relaxed != null'
qst actions | grep -q 'nmcli device reapply' && { qst actions; echo "put back before online"; exit 1; }
qst network connectivity full
qst wait '.controls.network.relaxed == null'
qst actions | grep -q 'nmcli device reapply' || { qst actions; echo "the profile's DNS was not put back"; exit 1; }

qst case "a VPN goes down and up on a click, and the pill takes them all"
open vpn
qst click ControlsPanel:row:wg0
qst wait '.controls.vpns == [{ name: "wg0", active: false, busy: null }]'
qst click ControlsPanel:row:wg0
qst wait '.controls.vpns == [{ name: "wg0", active: true, busy: null }]' 10
qst click ControlsPanel:pill:vpn
qst wait '.controls.vpns[0].active | not'

qst case "a VPN clicked while another comes up leaves that one's nmcli running"
qst network profile vpn Office
qst network delay 1500
open vpn
qst wait '(.controls.vpns | length) == 2'
qst click ControlsPanel:row:Office
qst wait '.controls.vpns | map(select(.name == "Office"))[0].busy == "up"'
qst click ControlsPanel:row:wg0
qst wait '.controls.vpns == [{ name: "Office", active: true, busy: null }, { name: "wg0", active: false, busy: null }]' 10
[ "$(qst actions | grep -c 'connection up')" = 1 ] || { qst actions; echo "the first nmcli was started again"; exit 1; }

qst case "the pill takes two VPNs down at once"
qst network profile vpn Office
qst network up Office
open vpn
qst wait '.controls.vpns | all(.active)'
qst click ControlsPanel:pill:vpn
qst wait '.controls.vpns | all((.active | not) and .busy == null)' 10

qst case "a VPN wanting a password asks in its row, and comes up with it"
qst network profile vpn Office
qst network vpn Office secrets
open vpn
qst wait '(.controls.vpns | length) == 2'
qst click ControlsPanel:row:Office
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
qst click ControlsPanel:row:Broken
qst wait 'any(.history[]; .summary == "Broken Failed to Connect")' 10
qst wait '.controls.vpns | map(select(.name == "Broken"))[0] | (.active | not) and .busy == null'

qst case "a new headset pairs, is trusted and connects in one click; a keyboard wanting a PIN says where to go"
qst bluetooth add 11:22:33:44:55:01 "WH-1000XM4" audio-headset ok
qst bluetooth add 11:22:33:44:55:02 "Keychron K3" input-keyboard pin
qst bluetooth add 11:22:33:44:55:03 ""
qst expect 'Failed to pair'
open bluetooth
qst wait '.controls.bluetooth.scanning and (.controls.bluetooth.devices | length) == 2'
qst click ControlsPanel:row:WH-1000XM4
qst wait '.controls.bluetooth.devices | map(select(.name == "WH-1000XM4"))[0] | .paired and .trusted and .connected'
qst click "ControlsPanel:row:Keychron K3"
qst wait '.controls.bluetooth.devices | map(select(.name == "Keychron K3"))[0].note == "Needs a PIN: use Bluetooth Settings"'
qst click ControlsPanel:row:WH-1000XM4
qst wait '.controls.bluetooth.devices | map(select(.name == "WH-1000XM4"))[0].connected | not'
qst ipc panels close > /dev/null
qst wait '(.controls.bluetooth.scanning | not)'

qst case "a paired device that fails to connect says so, though discovery finds another meanwhile"
qst bluetooth add 11:22:33:44:55:04 "JBL Flip" audio-speaker crowded paired
qst expect 'Failed to connect'
open bluetooth
qst wait '.controls.bluetooth.devices | map(select(.name == "JBL Flip"))[0].paired'
qst click "ControlsPanel:row:JBL Flip"
qst wait '(.controls.bluetooth.devices | map(.name) | index("Soundcore 2")) and (.controls.bluetooth.devices | map(select(.name == "JBL Flip"))[0].note == "Couldn'"'"'t connect")'

qst case "Bluetooth off says so in its menu, and Bluetooth Settings opens bluetui"
open bluetooth
qst click ControlsPanel:pill:bluetooth
qst wait '(.controls.bluetooth.on | not)'
qst click "ControlsPanel:action:Bluetooth Settings"
qst wait '.panel == ""'
qst actions | grep -q 'systemd-run.*bluetui' || { qst actions; echo "bluetui was not opened"; exit 1; }

qst case "night light: hyprsunset gets the strength, and the shell keeps it through a restart"
open
qst click ControlsPanel:pill:night
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
qst click ControlsPanel:pill:night
qst wait '(.controls.night.on | not)'

qst case "night light's strength is in its pill's menu, and moving it turns night light on"
open night
qst wait '.controls.night.present and (.controls.night.on | not)'
qst click ControlsPanel:slider:night 80 0
qst wait '.controls.night.on and .controls.night.temperature < 4000'
for _ in $(seq 50); do [ "$(qst x hyprctl hyprsunset temperature)" -lt 4000 ] && break; sleep 0.1; done # sleep: hyprsunset is outside the probe
[ "$(qst x hyprctl hyprsunset temperature)" -lt 4000 ] || { echo "hyprsunset is at $(qst x hyprctl hyprsunset temperature)"; exit 1; }
qst click ControlsPanel:menu:night
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

qst case "the centre's volume, and the microphone muted from elsewhere, show the OSD with what they set"
open
qst wait '.osdSettling == false'
qst click ControlsPanel:slider:output -60 0
qst wait '.osd.kind == "volume" and .osd.level < 0.6 and .osd.screen == "DP-1"'
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1
qst wait '.osd.kind == "microphone" and .osd.muted and .microphone.muted'
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
qst wait '.osd.kind == "microphone" and .osd.muted == false'

qst case "the sound menu heads its outputs and inputs alike, a symbol for each device and no mute, and Audio Settings opens pwvucontrol"
open
qst ipc controls menu sound > /dev/null
qst wait '.controls.menu == "sound" and (.controls.open.sound | length) == 8'
qst wait '.controls.open.sound[0:2] == ["# Output", "Speakers (speaker)"] and .controls.open.sound[4:6] == ["# Input", "Microphone (microphone)"]'
qst wait '(.controls.open.sound | sort) == (["# Output", "Speakers (speaker)", "Headphones (headphones)", "HDMI / DisplayPort (display)", "# Input", "Microphone (microphone)", "Headset Microphone (headset)", "Noise Cancelling (virtual)"] | sort)'
! qst areas 'ControlsPanel' | grep -q 'mute:input' || { echo "the sound menu still mutes the microphone"; exit 1; }
qst click 'ControlsPanel:action:Audio Settings'
qst wait '.panel == ""'
for _ in $(seq 20); do qst actions | grep -q 'systemd-run --user --scope --quiet pwvucontrol' && break; sleep 0.1; done # sleep: the launch is logged by a process the shell detached
qst actions | grep -q 'systemd-run --user --scope --quiet pwvucontrol' || { qst actions; echo "pwvucontrol was not run"; exit 1; }

qst case "without a battery the header shows the machine, and a battery takes its place back"
qst battery remove
open
qst wait '.machine.header == true and .machine.hostname != "" and .machine.icon and (.machine.uptime | startswith("Up "))'
qst battery 40 discharging 1800
qst wait '.machine.header == false'

qst case "the player that played last gets the card; stopped, it goes"
# alone: removing a playing player races Quickshell polling its position, and a loaded machine widens the race
# The race can lose the poll's reply as the player leaves the bus.
qst expect --may 'Error updating property org.mpris.MediaPlayer2.firefox'
qst expect --may 'Message recipient disconnected from message bus without replying'
qst player add spotify Spotify Playing
qst player add firefox Firefox Paused
center
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
qst ipc controls menu sound > /dev/null
qst wait '.controls.menu == "sound"'
qst click ControlsPanel:row:Headphones
qst wait '.volume.output == "Headphones"'
qst stays '.panel == "controls:DP-1" and .controls.menu == "sound"' 0.5

qst case "a microphone without an output keeps the volume row, dim, whose arrow still opens Sound for it"
for node in test-speakers test-headphones test-hdmi; do qst x pw-cli destroy "$node" > /dev/null; done
qst wait '.volume.output == null and .microphone.input == "Microphone"'
open
qst areas ControlsPanel | grep -q $'slider:output\tfalse'
qst click ControlsPanel:menu:sound
qst wait '.controls.menu == "sound" and .controls.open == { count: 3, rows: 4, first: ["Input", "Microphone", "Headset Microphone", "Noise Cancelling"], sound: ["# Input", "Microphone (microphone)", "Headset Microphone (headset)", "Noise Cancelling (virtual)"] }'
qst click ControlsPanel:row:Headset
qst wait '.microphone.input == "Headset Microphone"'

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
qst click ControlsPanel:header:screenshot
qst wait '.panel == ""'
for _ in $(seq 30); do qst actions | grep -q 'freeze-region copy' && break; sleep 0.1; done # sleep: the screenshot waits out the centre's fade, which the probe does not see
qst actions | grep -qx 'systemd-run --user --scope --quiet freeze-region copy'
open
qst click ControlsPanel:header:lock
qst wait '.panel == ""'
qst actions | grep -qx 'loginctl lock-session'
open
qst click ControlsPanel:header:power
qst wait '.panel == "power"'

qst case "what records gets an In use pill naming the app, which raises its window"
qst spawn foot
qst wait '.windows | length == 1'
qst spawn pw-record -P "{ application.name=foot }" /dev/null
qst wait '.privacy.mic == ["foot"]'
open
for _ in $(seq 30); do qst areas 'ControlsPanel' | grep -q "inuse:Microphone	true" && break; sleep 0.1; done # sleep: the window list reaches the pill through wlr-foreign-toplevel, outside the probe
qst click ControlsPanel:inuse:Microphone
qst wait '.panel == ""'

qst case "a Bluetooth device's charge and link are drawn in its row"
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70
qst wait '.controls.bluetooth.devices[0].battery == 70'
open bluetooth
qst area ControlsPanel:row:Headset > /dev/null

qst case "the player's progress shows where the track is as the center opens, and seeks where it is clicked"
qst player add spotify Spotify
center
qst wait '.controls.media.position >= 96 and .controls.media.position < 110 and .controls.media.length == 251'
qst click NotificationCenter:slider:media
qst wait '.controls.media.position > 115 and .controls.media.position < 140'

qst case "a length the player drops from a new track's metadata as it plays stays on the card, as Firefox drops it on YouTube"
qst player add spotify Spotify
center
qst wait '.controls.media.length == 251'
dbus-send --session --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next > /dev/null
qst wait '.controls.media.title == "Kid A"'
qst stays '.controls.media.length == 284' 1
qst area NotificationCenter:slider:media > /dev/null

qst case "past 100 % the output's slider reaches as far as the level, marks 100 %, and a click sets a share of that range"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.3
qst wait '.volume.percent == 130'
open
qst wait '(.sliders | map(select(.name == "slider:output"))[0].span * 100 | round) == 130'
qst click ControlsPanel:slider:output
qst wait '.volume.percent == 65'
qst stays '.volume.percent == 65' 0.5

qst case "Escape mid-drag puts the level back where the drag began and keeps the centre open; Escape after closes it"
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4
open
qst wait '.volume.percent == 40'
at=$(qst area ControlsPanel:slider:output)
read -r x y <<< "$at"
qst drag $((x - 60)) "$y" 180 0 2500 &
qst wait '.volume.percent > 50'
qst key Escape
wait
qst wait '.volume.percent == 40'
qst stays '.panel == "controls:DP-1" and .volume.percent == 40' 0.6
qst key Escape
qst wait '.panel == ""'

qst case "the keyboard reaches every control in the centre: Tab and the arrows move a ring, Space toggles a pill, Return opens its menu, the arrows step a slider, Escape shuts the menu before the centre"
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
# On to the first pill, Wired, past the volume's arrow.
qst key Tab Tab
qst wait '.focused == "ControlsPanel/Pill"'
qst key space
qst wait '.controls.toggles[0].on == false'
qst key Tab
qst key Return
qst wait '.controls.menu == "wifi"'
qst key Escape
qst wait '.controls.menu == "" and .panel == "controls:DP-1"'
qst key Escape
qst wait '.panel == ""'
