pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.common
import qs.nix
import "devices.js" as Devices
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
  readonly property string glyph: glyphFor(volume, muted)
  // What the popup lists: every output, the one in use marked.
  readonly property var devices: fake ? fake.devices.map((name, i) => ({ name: Names.clean(name), current: i === fake.current, index: i, id: i })) : outputs.map((node, i) => ({ name: Names.clean(node.description || node.nickname || node.name), current: node === sink, index: i, id: node.id, props: node.properties }))
  // The hardware behind them: one that also records is a headset.
  readonly property var hardware: new Set(devices.map(device => device.props?.["device.id"]).filter(id => id !== undefined))
  readonly property string kind: sink ? Devices.kind(sink.properties, false, Microphone.hardware.has(sink.properties["device.id"])) : "speaker"

  function glyphFor(level: real, silenced: bool): string {
    return silenced ? Symbols.volumeOff : level <= 0.001 ? Symbols.volumeMute : level < 0.5 ? Symbols.volumeDown : Symbols.volumeUp;
  }

  // A device's symbol by what devices.js makes of it, in the sound menu and the OSD alike.
  function kindGlyph(kind: string): string {
    return { headphones: Symbols.headphones, headset: Symbols.headset, display: Symbols.speakerDisplay, microphone: Symbols.mic, webcam: Symbols.camera, virtual: Symbols.audioVirtual }[kind] ?? Symbols.speaker;
  }

  // Up to 100 %, or as far past it as something else set it or a slider's range began, so turning it up never turns it down.
  function setVolume(value: real, reach: real): void {
    const clamped = Math.max(0, Math.min(Math.max(1, root.volume, reach), value));
    if (fake) fake = Object.assign({}, fake, { volume: clamped, muted: false });
    else if (sink?.audio) {
      sink.audio.volume = clamped;
      if (clamped > 0) sink.audio.muted = false;
    }
  }

  // Five percent a notch, onto the five percent marks.
  function step(notches: int): void {
    setVolume(Math.round((root.volume + notches * 0.05) * 20) / 20, 1);
  }

  function toggleMute(): void {
    if (fake) fake = Object.assign({}, fake, { muted: !fake.muted });
    else if (sink?.audio) sink.audio.muted = !sink.audio.muted;
  }

  function settings(): void {
    Panels.close();
    Detached.run(["pwvucontrol"], "");
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
