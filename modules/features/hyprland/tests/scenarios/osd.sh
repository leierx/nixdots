export QS_TEST_MONITORS="DP-1:1920x1080:1 DP-2:1920x1080:1"

node() { pw-dump | jq -r --arg name "$1" '.[] | select(.info.props["node.name"] == $name) | .id'; }
# Each case starts once the OSD has taken in what PipeWire has, as it does at login.
settled() { qst wait '.osdSettling == false and .volume.output != null'; }
# How many times the OSD has shown, now.
shown() { qst state .osdShown; }

qst case "nothing shows as the shell starts"
qst stays '.osd == null' 2

qst case "a volume change shows the new level on the focused monitor, and goes"
settled
qst focus DP-2
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3
qst wait '.osd.kind == "volume" and .osd.title == "Speakers" and (.osd.level * 100 | round) == 30 and .osd.screen == "DP-2" and .osd.muted == false'
qst wait '.layers | index("DP-2 quickshell:osd")'
qst wait '.osd == null'
qst wait '.layers | index("DP-2 quickshell:osd") | not'

qst case "muting shows the level, muted"
settled
wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
qst wait '.osd.kind == "volume" and .osd.muted'

qst case "a level past 100 % shows as it is"
settled
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.3
qst wait '.osd.kind == "volume" and (.osd.level * 100 | round) == 130'

qst case "a media key shows the level even where it changes nothing"
settled
qst x hyprctl dispatch 'hl.dsp.global("quickshell:osd-volume")' > /dev/null
qst wait '.osd.kind == "volume" and (.osd.level * 100 | round) == 64'

qst case "a volume key steps once a press, and at 100 % still shows"
settled
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1
qst wait '.volume.percent == 100'
qst key XF86AudioLowerVolume
qst wait '.volume.percent == 95 and (.osd.level * 100 | round) == 95'
qst stays '.volume.percent == 95'
qst key XF86AudioRaiseVolume
qst wait '.volume.percent == 100'
before=$(shown)
qst key XF86AudioRaiseVolume
qst wait ".osdShown > $before and .osd.level == 1"
qst stays '.volume.percent == 100'

qst case "switching the default output shows the new one once, and not its level"
settled
before=$(shown)
wpctl set-default "$(node test-headphones)"
qst wait '.osd.kind == "output" and .osd.title == "Headphones"'
qst stays ".osd.kind == \"output\" and .osdShown == $((before + 1))"

qst case "a volume change on the new output shows once it has settled"
settled
wpctl set-default "$(node test-headphones)"
qst wait '.osd.kind == "output"'
qst wait '.osd == null'
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.2
qst wait '.osd.kind == "volume" and .osd.title == "Headphones" and (.osd.level * 100 | round) == 20'

qst case "unplugging the default output shows the one PipeWire falls back to"
settled
before=$(shown)
pw-cli destroy "$(node test-speakers)" > /dev/null
qst wait '.volume.output == "Headphones" and .osd.kind == "output" and .osd.title == "Headphones"'
qst stays ".osdShown == $((before + 1))"

qst case "PipeWire restarting shows nothing"
settled
qst pipewire restart
qst wait '.volume.output == "Speakers" and .input == "Microphone"' 10
qst stays '.osd == null' 2

qst case "the control centre's slider stands in for the OSD"
settled
qst ipc panels open controls:DP-1 > /dev/null
qst wait '.panel == "controls:DP-1"'
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5
qst wait '.volume.percent == 50'
qst stays '.osd == null'

qst case "muting the microphone shows it, and unmuting"
settled
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1
qst wait '.osd.kind == "microphone" and .osd.title == "Microphone" and .osd.muted'
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
qst wait '.osd.kind == "microphone" and .osd.muted == false'

qst case "the microphone's level is no OSD"
settled
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.4
qst stays '.osd == null'

qst case "switching the default input shows the new one"
settled
wpctl set-default "$(node test-headset-mic)"
qst wait '.osd.kind == "input" and .osd.title == "Headset Microphone"'

qst case "a backlight showing up is no change, a change after it shows"
settled
qst backlight intel_backlight 40
qst stays '.osd == null'
qst backlight intel_backlight 60
qst wait '.osd.kind == "brightness" and (.osd.level * 100 | round) == 60'

qst case "of two backlights, the one that changed shows, on its own scale"
settled
qst backlight intel_backlight 40
qst backlight acpi_video0 5 10
qst stays '.osd == null'
qst backlight acpi_video0 8 10
qst wait '.osd.kind == "brightness" and (.osd.level * 100 | round) == 80'

qst case "a backlight going is no change, and a brightness key with none shows nothing"
settled
qst backlight intel_backlight 40
qst backlight intel_backlight remove
qst x hyprctl dispatch 'hl.dsp.global("quickshell:osd-brightness")' > /dev/null
qst stays '.osd == null'

qst case "a brightness key shows the level even where it changes nothing"
settled
qst backlight intel_backlight 100
qst x hyprctl dispatch 'hl.dsp.global("quickshell:osd-brightness")' > /dev/null
qst wait '.osd.kind == "brightness" and .osd.level == 1'

qst case "Caps Lock shows on, and off"
settled
qst wait '.caps == false'
qst key Caps_Lock
qst wait '.caps and .osd.kind == "caps" and .osd.muted == false'
qst key Caps_Lock
qst wait '.caps == false and .osd.kind == "caps" and .osd.muted'

qst case "other keys show nothing"
settled
qst key a Escape Return
qst stays '.osd == null'

qst case "an OSD showing while its monitor goes, and the next one on a monitor still there"
settled
qst focus DP-2
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3
qst wait '.osd.screen == "DP-2"'
qst monitor remove DP-2
qst wait '(.screens | length) == 1'
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4
qst wait '.osd.screen == "DP-1" and (.osd.level * 100 | round) == 40'
qst wait '.layers | index("DP-1 quickshell:osd")'
