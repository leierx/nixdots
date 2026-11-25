pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// hyprsunset's tint, set through `hyprctl hyprsunset`; the shell keeps it, as hyprsunset starts again untinted.
Singleton {
  id: root

  readonly property int warmest: 2500
  readonly property int lightest: 5500
  // hyprsunset answers: it runs, under Hyprland.
  property bool present: false
  readonly property bool on: saved.on
  readonly property int temperature: Math.max(warmest, Math.min(lightest, saved.temperature))
  // 0 at its lightest, 1 at its warmest, for the slider.
  readonly property real strength: (lightest - temperature) / (lightest - warmest)

  function toggle(): void {
    saved.on = !saved.on;
    root.apply();
  }

  // Moving the strength of a night light that is off turns it on.
  function setStrength(value: real): void {
    saved.on = true;
    saved.temperature = Math.round((root.lightest - Math.max(0, Math.min(1, value)) * (root.lightest - root.warmest)) / 50) * 50;
    // A drag sets it many times a second; hyprsunset gets the latest a frame later.
    Qt.callLater(root.apply);
  }

  function apply(): void {
    if (!root.present) return;
    if (set.running) {
      set.again = true;
      return;
    }
    set.command = ["hyprctl", "hyprsunset", ...(root.on ? ["temperature", `${root.temperature}`] : ["identity"])];
    set.running = true;
  }

  StateFile {
    name: "night-light.json"

    JsonAdapter {
      id: saved

      property bool on: false
      property int temperature: 4000
    }
  }

  Process {
    id: set

    property bool again: false

    onExited: {
      if (!again) return;
      again = false;
      root.apply();
    }
  }

  Deadline {
    process: set
    interval: 5000
  }

  // Its getter keeps the last temperature through identity, but a hyprsunset started again reads its own default.
  Process {
    id: query

    command: ["hyprctl", "hyprsunset", "temperature"]
    stdout: StdioCollector {
      onStreamFinished: {
        const temperature = parseInt(text.trim());
        const was = root.present;
        root.present = Number.isFinite(temperature);
        if (root.present && (!was || root.on && temperature !== root.temperature)) root.apply();
      }
    }
  }

  Deadline {
    process: query
    interval: 5000
  }

  Timer {
    interval: 10000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: if (!query.running) query.running = true
  }
}
