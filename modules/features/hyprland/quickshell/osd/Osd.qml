pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.bar
import qs.common

// Changes as they are made, not states as they are found: the first value of anything, and any
// that arrive while what it belongs to has just changed (another output, PipeWire back), are only
// taken in.
Singleton {
  id: root

  // { kind, title, level, muted }: kind is volume, microphone, output, input, brightness or caps.
  property var current: null
  property string screen: ""
  // Bumped on every show, so showing the same again restarts the timeout.
  property int serial: 0

  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property string sourceKey: source?.name ?? ""
  readonly property string sourceName: source ? source.description || source.nickname || source.name : ""
  // Still taking in what it found, so a change now would not show; for tests.
  readonly property bool settling: [volumeWatch, micWatch].some(watch => watch.settle.running) || [outputWatch, inputWatch].some(watch => watch.settle.running || watch.key !== "" && watch.known === "")

  function show(item: var): void {
    root.current = item;
    root.screen = Screens.focused;
    root.serial++;
    timeout.restart();
  }

  function showVolume(): void {
    if (Volume.present) root.show({ kind: "volume", title: Volume.name, level: Volume.volume, muted: Volume.muted });
  }

  function showBrightness(): void {
    if (Brightness.device !== "") root.show({ kind: "brightness", title: "Brightness", level: Brightness.level, muted: false });
  }

  Timer {
    id: timeout

    interval: 1500
    onTriggered: root.current = null
  }

  // A node's mute only arrives while something tracks it.
  PwObjectTracker {
    objects: [root.source]
  }

  // The values of one thing, `key`; a new key, or the thing becoming ready, starts it over.
  component Watch: QtObject {
    id: watch

    required property string key
    required property bool ready
    required property var value
    property string seenKey: ""
    property bool seenReady: false
    property string seen: ""
    property Timer settle: Timer {
      interval: 500
    }

    signal noticed()

    // Later, as the key and the value update in either order within one change.
    function check(): void {
      const value = JSON.stringify(watch.value);
      if (watch.key !== watch.seenKey || watch.ready !== watch.seenReady) {
        watch.seenKey = watch.key;
        watch.seenReady = watch.ready;
        watch.settle.restart();
      } else if (watch.key !== "" && watch.ready && !watch.settle.running && value !== watch.seen) {
        watch.noticed();
      }
      watch.seen = value;
    }

    onKeyChanged: Qt.callLater(check)
    onReadyChanged: Qt.callLater(check)
    onValueChanged: Qt.callLater(check)
    Component.onCompleted: {
      seenKey = key;
      seenReady = ready;
      seen = JSON.stringify(value);
      settle.restart();
    }
  }

  // The default device once it settles: unplugging one has none for a moment before the next, and
  // PipeWire coming back brings the same one back.
  component DeviceWatch: QtObject {
    id: device

    required property string key
    property string known: ""
    property Timer settle: Timer {
      interval: 400
      onTriggered: {
        if (device.key === "") return;
        if (device.known !== "" && device.key !== device.known) device.switched();
        device.known = device.key;
      }
    }

    signal switched()

    onKeyChanged: settle.restart()
    Component.onCompleted: settle.restart()
  }

  Watch {
    id: volumeWatch

    key: Volume.key
    ready: Volume.ready
    value: [Volume.volume, Volume.muted]
    // Its popup's slider shows the level already.
    onNoticed: if (!Panels.active.startsWith("volume:")) root.showVolume()
  }

  Watch {
    id: micWatch

    key: root.sourceKey
    ready: (root.source?.ready ?? false) && root.source.audio !== null
    value: root.source?.audio?.muted ?? false
    onNoticed: root.show({ kind: "microphone", title: root.sourceName, level: null, muted: root.source.audio.muted })
  }

  DeviceWatch {
    id: outputWatch

    key: Volume.key
    onSwitched: root.show({ kind: "output", title: Volume.name, level: null, muted: false })
  }

  DeviceWatch {
    id: inputWatch

    key: root.sourceKey
    onSwitched: root.show({ kind: "input", title: root.sourceName, level: null, muted: false })
  }

  Connections {
    target: Brightness

    function onAdjusted(): void {
      root.showBrightness();
    }
  }

  Connections {
    target: CapsLock

    function onToggled(): void {
      root.show({ kind: "caps", title: "Caps Lock", level: null, muted: !CapsLock.on });
    }
  }

  // The media keys, so a level at its end still shows when the key changes nothing.
  GlobalShortcut {
    name: "osd-volume"
    onPressed: root.showVolume()
  }

  GlobalShortcut {
    name: "osd-brightness"
    onPressed: root.showBrightness()
  }
}
