pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "names.js" as Names
import qs.common

// PipeWire's default input, and the sources to pick it from.
Singleton {
  id: root

  readonly property PwNode source: Pipewire.defaultAudioSource
  // Quickshell types only plain sources; a virtual one is told by its media.class, which arrives only while tracked.
  readonly property var untyped: Pipewire.nodes.values.filter(node => node.type === PwNodeType.Untracked && !node.isStream)
  readonly property var inputs: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSource || node.type === PwNodeType.Untracked && !node.isStream && node.ready && /^Audio\/Source/.test(node.properties["media.class"] ?? ""))
  readonly property bool present: source !== null || inputs.length > 0
  // An untyped node has no audio, so no level or mute to set.
  readonly property bool adjustable: (source?.audio ?? null) !== null
  readonly property real volume: source?.audio?.volume ?? 0
  readonly property bool muted: source?.audio?.muted ?? false
  readonly property int percent: Math.round(volume * 100)
  // Material Symbols' mic and mic_off
  readonly property string on: "M480-400q-50 0-85-35t-35-85v-240q0-50 35-85t85-35q50 0 85 35t35 85v240q0 50-35 85t-85 35Zm-40 240v-83q-92-13-157.5-78T203-479q-2-17 9-29t28-12q17 0 28.5 11.5T284-480q14 70 69.5 115T480-320q72 0 127-45.5T676-480q4-17 15.5-28.5T720-520q17 0 28 12t9 29q-14 91-79 157t-158 79v83q0 17-11.5 28.5T480-120q-17 0-28.5-11.5T440-160Z"
  readonly property string off: "M672-377q-14-8-18-24.5t4-30.5q7-11 11.5-23.5T676-481q4-17 15.5-28t28.5-11q17 0 28 12t9 29q-3 23-10.5 45T727-392q-8 14-24.5 18.5T672-377ZM532-542 383-691q-11-11-17-25.5t-6-30.5v-13q0-50 35-85t85-35q50 0 85 35t35 85v189q0 27-24.5 37.5T532-542Zm-92 382v-84q-92-12-157.5-77T203-479q-2-17 9-29t28-12q17 0 28.5 11.5T284-480q14 70 69.5 115T480-320q34 0 64.5-10.5T600-360l57 57q-29 23-63.5 38.5T520-244v84q0 17-11.5 28.5T480-120q-17 0-28.5-11.5T440-160Zm324 76L84-764q-11-11-11-28t11-28q11-11 28-11t28 11l680 680q11 11 11 28t-11 28q-11 11-28 11t-28-11Z"
  readonly property string glyph: muted ? off : on
  readonly property string name: source ? Names.clean(source.description || source.nickname || source.name) : ""
  // The next default for wpctl while it is still setting one.
  property string queued: ""
  readonly property var devices: inputs.map((node, i) => ({ name: Names.clean(node.description || node.nickname || node.name), current: node === source, index: i }))

  // Up to 100 %, or as far past it as something else set it, as the output's.
  function setVolume(value: real): void {
    if (!source?.audio) return;
    const clamped = Math.max(0, Math.min(Math.max(1, root.volume), value));
    source.audio.volume = clamped;
    if (clamped > 0) source.audio.muted = false;
  }

  function step(notches: int): void {
    setVolume(Math.round((root.volume + notches * 0.05) * 20) / 20);
  }

  function toggleMute(): void {
    if (source?.audio) source.audio.muted = !source.audio.muted;
  }

  function choose(index: int): void {
    const node = inputs[index];
    if (!node) return;
    // Behind a wpctl still running, so the last pick wins.
    if (node.type === PwNodeType.AudioSource && !pick.running) Pipewire.preferredDefaultAudioSource = node;
    else root.setDefault(`${node.id}`);
  }

  // Quickshell takes only a source it types as the default, so a virtual one goes through wpctl, one at a time.
  function setDefault(id: string): void {
    if (pick.running) {
      root.queued = id;
    } else {
      pick.command = ["wpctl", "set-default", id];
      pick.running = true;
    }
  }

  function next(): void {
    const id = root.queued;
    root.queued = "";
    if (id !== "") root.setDefault(id);
  }

  Command {
    id: pick

    name: "Input"
    onDone: root.next()
    onFailed: root.next()
  }

  PwObjectTracker {
    objects: [root.source, ...root.inputs, ...root.untyped]
  }
}
