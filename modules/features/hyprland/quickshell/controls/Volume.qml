pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "names.js" as Names

// PipeWire's default output; `fake` stands in where there is no sound server, as in qs-test.
Singleton {
  id: root

  property var fake: null

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property var outputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio)
  readonly property bool present: fake !== null || (sink?.audio ?? null) !== null
  // What the level belongs to: a new one is a switch of output, not a change of level.
  readonly property string key: fake ? `fake:${fake.current}` : sink?.name ?? ""
  readonly property string name: Names.clean(fake ? fake.devices[fake.current] ?? "" : sink ? sink.description || sink.nickname || sink.name : "")
  readonly property bool ready: fake !== null || (sink?.ready ?? false) && sink.audio !== null
  readonly property real volume: fake?.volume ?? sink?.audio?.volume ?? 0
  readonly property bool muted: fake?.muted ?? sink?.audio?.muted ?? false
  readonly property int percent: Math.round(volume * 100)
  // Material Symbols' volume_up, volume_down, volume_mute and volume_off
  readonly property string up: "M760-481q0-83-44-151.5T598-735q-15-7-22-21.5t-2-29.5q6-16 21.5-23t31.5 0q97 43 155 131.5T840-481q0 108-58 196.5T627-153q-16 7-31.5 0T574-176q-5-15 2-29.5t22-21.5q74-34 118-102.5T760-481ZM280-360H160q-17 0-28.5-11.5T120-400v-160q0-17 11.5-28.5T160-600h120l132-132q19-19 43.5-8.5T480-703v446q0 27-24.5 37.5T412-228L280-360Zm380-120q0 42-19 79.5T591-339q-10 6-20.5.5T560-356v-250q0-12 10.5-17.5t20.5.5q31 25 50 63t19 80ZM400-606l-86 86H200v80h114l86 86v-252ZM300-480Z"
  readonly property string down: "M360-360H240q-17 0-28.5-11.5T200-400v-160q0-17 11.5-28.5T240-600h120l132-132q19-19 43.5-8.5T560-703v446q0 27-24.5 37.5T492-228L360-360Zm380-120q0 42-19 79.5T671-339q-10 6-20.5.5T640-356v-250q0-12 10.5-17.5t20.5.5q31 25 50 63t19 80ZM480-606l-86 86H280v80h114l86 86v-252ZM380-480Z"
  readonly property string mute: "M440-360H320q-17 0-28.5-11.5T280-400v-160q0-17 11.5-28.5T320-600h120l132-132q19-19 43.5-8.5T640-703v446q0 27-24.5 37.5T572-228L440-360Zm-80-80h114l86 86v-252l-86 86H360v80Zm100-40Z"
  readonly property string off: "M671-177q-11 7-22 13t-23 11q-15 7-30.5 0T574-176q-6-15 1.5-29.5T598-227q7-3 13-6.5t12-7.5L480-368v111q0 27-24.5 37.5T412-228L280-360H160q-17 0-28.5-11.5T120-400v-160q0-17 11.5-28.5T160-600h88L84-764q-11-11-11-28t11-28q11-11 28-11t28 11l680 680q11 11 11 28t-11 28q-11 11-28 11t-28-11l-93-93Zm89-304q0-83-44-151.5T598-735q-15-7-22-21.5t-2-29.5q6-16 21.5-23t31.5 0q97 43 155 131t58 197q0 33-6 65.5T817-353q-8 22-24.5 27.5t-30.5.5q-14-5-22.5-18t-.5-30q11-26 16-52.5t5-55.5ZM591-623q33 21 51 63t18 80v10q0 5-1 10-2 13-14 17t-22-6l-51-51q-6-6-9-13.5t-3-15.5v-77q0-12 10.5-17.5t20.5.5Zm-201-59q-6-6-6-14t6-14l22-22q19-19 43.5-8.5T480-703v63q0 14-12 19t-22-5l-56-56Zm10 328v-94l-72-72H200v80h114l86 86Zm-36-130Z"
  readonly property string glyph: glyphFor(volume, muted)
  // What the popup lists: every output, the one in use marked.
  readonly property var devices: fake ? fake.devices.map((name, i) => ({ name: Names.clean(name), current: i === fake.current, index: i })) : outputs.map((node, i) => ({ name: Names.clean(node.description || node.nickname || node.name), current: node === sink, index: i }))

  function glyphFor(level: real, silenced: bool): string {
    return silenced ? off : level <= 0.001 ? mute : level < 0.5 ? down : up;
  }

  // Up to 100 %, or as far past it as something else set it, so turning it up never turns it down.
  function setVolume(value: real): void {
    const clamped = Math.max(0, Math.min(Math.max(1, root.volume), value));
    if (fake) fake = Object.assign({}, fake, { volume: clamped, muted: false });
    else if (sink?.audio) {
      sink.audio.volume = clamped;
      if (clamped > 0) sink.audio.muted = false;
    }
  }

  // Five percent a notch, onto the five percent marks.
  function step(notches: int): void {
    setVolume(Math.round((root.volume + notches * 0.05) * 20) / 20);
  }

  function toggleMute(): void {
    if (fake) fake = Object.assign({}, fake, { muted: !fake.muted });
    else if (sink?.audio) sink.audio.muted = !sink.audio.muted;
  }

  function choose(index: int): void {
    if (fake) fake = Object.assign({}, fake, { current: index });
    else if (outputs[index]) Pipewire.preferredDefaultAudioSink = outputs[index];
  }

  // A node's volume and mute only arrive while something tracks it.
  PwObjectTracker {
    objects: [root.sink, ...root.outputs]
  }
}
