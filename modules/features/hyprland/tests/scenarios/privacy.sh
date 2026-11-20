export QS_TEST_MONITORS="DP-1:1920x1080:1"

node() { pw-dump | jq -r --arg name "$1" '.[] | select(.info.props["node.name"] == $name) | .id'; }
# pw-record with these properties, in the background; its pid is $!.
record() { pw-record -P "{ $1 }" "${@:2}" /dev/null > /dev/null 2>&1 & }

qst case "nothing recording shows nothing"
qst stays '.privacy == { mic: [], screen: null, camera: null } and (.layers | length) > 0'

qst case "an app recording the microphone shows by name, and goes when it stops"
record 'application.name = Zoom' --target test-mic
zoom=$!
qst wait '.privacy.mic == ["Zoom"]'
kill $zoom
qst wait '.privacy.mic == []'

qst case "the default microphone counts, whichever it is"
wpctl set-default "$(node test-headset-mic)"
qst wait '.input == "Headset Microphone"'
record 'application.name = Discord'
qst wait '.privacy.mic == ["Discord"]'

qst case "two apps recording are both named, once each"
record 'application.name = Zoom' --target test-mic
record 'application.name = Zoom' --target test-headset-mic
record 'application.name = Discord' --target test-mic
qst wait '(.privacy.mic | sort) == ["Discord", "Zoom"]'

qst case "a virtual microphone (a filter's) counts"
record 'application.name = Denoised' --target test-virtual-mic
qst wait '.privacy.mic == ["Denoised"]'

qst case "a level meter is no recording"
record 'application.name = Meter stream.monitor = true' --target test-mic
record 'application.name = Pavucontrol application.id = org.PulseAudio.pavucontrol' --target test-mic
qst stays '.privacy.mic == []' 2

qst case "recording what plays (a sink's monitor) is no microphone"
record 'application.name = Visualizer stream.capture.sink = true' --target test-speakers
qst stays '.privacy.mic == []' 2

qst case "PipeWire going away takes it down, and coming back finds what records again"
record 'application.name = Zoom' --target test-mic
qst wait '.privacy.mic == ["Zoom"]'
qst pipewire stop
qst wait '.privacy.mic == []'
qst pipewire start
qst wait '.volume.output == "Speakers"' 10
record 'application.name = Zoom' --target test-mic
qst wait '.privacy.mic == ["Zoom"]'

qst case "a screen cast through the portal shows until it ends"
# PipeWire reports the cast's client gone as it is killed.
qst expect --may 'Pipewire error on object 0 with code -32'
pw-cli -m create-node adapter '{ factory.name = videotestsrc node.name = xdph-streaming-1 media.class = Video/Source }' < /dev/null > /dev/null 2>&1 &
cast=$!
qst wait '.privacy.screen == []'
kill $cast
qst wait '.privacy.screen == null'

qst case "a camera through PipeWire is a camera, not a screen cast"
pw-cli -m create-node adapter '{ factory.name = videotestsrc node.name = v4l2_input.test device.api = v4l2 media.class = Video/Source }' < /dev/null > /dev/null 2>&1 &
qst wait '(.privacy | .screen == null and .camera == null)'
qst stays '.privacy.screen == null and .privacy.camera == null'

qst case "an app holding the camera open shows after a moment, by its name"
qst camera open zoom
qst wait '.privacy.camera == ["zoom"]'
qst camera close zoom
qst wait '.privacy.camera == null'

qst case "a camera opened only to be listed, as a browser does, shows nothing"
qst camera open chrome
qst camera close chrome
qst stays '.privacy.camera == null' 2

qst case "PipeWire's own hold on a camera is its clients', not its own"
qst camera open pipewire
qst camera open wireplumber
qst stays '.privacy.camera == null' 2

qst case "two apps on two cameras, one plugged in after the shell started"
qst camera add video1
qst camera open zoom
qst camera open obs video1
qst wait '(.privacy.camera | sort) == ["obs", "zoom"]'
qst camera close zoom
qst wait '.privacy.camera == ["obs"]'

qst case "a camera plugged in shows once udev hands it to the user, though it came root's alone"
qst camera add video1 locked
qst stays '.privacy.camera == null' 0.5
qst camera unlock video1
qst camera open obs video1
qst wait '.privacy.camera == ["obs"]'

qst case "a camera unplugged while in use goes with it"
qst camera open zoom
qst wait '.privacy.camera == ["zoom"]'
qst camera remove video0
qst wait '.privacy.camera == null'

qst case "everything at once is three kinds in the bar's order"
record 'application.name = Zoom' --target test-mic
qst camera open zoom
pw-cli -m create-node adapter '{ factory.name = videotestsrc node.name = xdph-streaming-2 media.class = Video/Source }' < /dev/null > /dev/null 2>&1 &
qst wait '.privacy.mic == ["Zoom"] and .privacy.camera == ["zoom"] and .privacy.screen == []'
