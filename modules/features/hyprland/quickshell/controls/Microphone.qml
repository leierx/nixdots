pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "names.js" as Names
import qs.common
import qs.nix

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
  readonly property string glyph: muted ? Symbols.micOff : Symbols.mic
  readonly property string name: source ? Names.clean(source.description || source.nickname || source.name) : ""
  // The next default for wpctl while it is still setting one.
  property string queued: ""
  readonly property var devices: inputs.map((node, i) => ({ name: Names.clean(node.description || node.nickname || node.name), current: node === source, index: i }))

  // Up to 100 %, or as far past it as something else set it, as the output's.
  function setVolume(value: real, reach: real): void {
    if (!source?.audio) return;
    const clamped = Math.max(0, Math.min(Math.max(1, root.volume, reach), value));
    source.audio.volume = clamped;
    if (clamped > 0) source.audio.muted = false;
  }

  function step(notches: int): void {
    setVolume(Math.round((root.volume + notches * 0.05) * 20) / 20, 1);
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
