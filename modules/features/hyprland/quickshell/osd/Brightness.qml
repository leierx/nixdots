pragma Singleton

import QtQuick
import Quickshell
import qs.common

Singleton {
  id: root

  // name: { brightness, max }
  property var devices: ({})
  // The one changed last, or the first.
  property string device: ""
  readonly property real level: devices[device] ? devices[device].brightness / devices[device].max : 0
  // Each start of the watcher reports what is, which is no change.
  property bool known: false

  signal adjusted()

  // The level asked for last, set once the one before it is done, so a drag never queues up.
  property var target: null

  // Through logind, so brightnessctl needs no rights of its own; never quite off, which would leave nothing to see.
  function set(name: string, value: real): void {
    root.target = { name, percent: Math.max(1, Math.min(100, Math.round(value * 100))) };
    if (!setter.running) root.flush();
  }

  function flush(): void {
    if (!root.target) return;
    setter.command = ["brightnessctl", "--quiet", "--device", root.target.name, "set", `${root.target.percent}%`];
    root.target = null;
    setter.running = true;
  }

  Command {
    id: setter

    name: "Brightness"
    // A drag runs one per step: a failure shows as the slider going back to the level backlight-watch hears.
    quiet: true
    // Once it has stopped running: started from its own exit, the next would be dropped, or fail unreported.
    onDone: Qt.callLater(root.flush)
    onFailed: Qt.callLater(root.flush)
  }

  function read(line: string): void {
    const next = {};
    for (const part of line.split(";")) {
      const [name, brightness, max] = part.trim().split(" ");
      if (name && Number(max) > 0 && Number.isFinite(Number(brightness))) next[name] = { brightness: Number(brightness), max: Number(max) };
    }
    const moved = root.known ? Object.keys(next).find(name => root.devices[name]?.max === next[name].max && root.devices[name].brightness !== next[name].brightness) : undefined;
    root.devices = next;
    root.known = true;
    if (moved !== undefined) root.device = moved;
    else if (!next[root.device]) root.device = Object.keys(next)[0] ?? "";
    if (moved !== undefined) root.adjusted();
  }

  Watcher {
    id: watcher

    command: ["backlight-watch"]
    onLine: line => root.read(line)
    onStopped: root.known = false
  }
}
