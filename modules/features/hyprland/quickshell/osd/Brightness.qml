pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every backlight's level from backlight-watch, which hears each change however it was made.
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

  Process {
    id: watcher

    property int failures: 0

    running: true
    command: ["backlight-watch"]
    stdout: SplitParser {
      onRead: line => {
        watcher.failures = 0;
        root.read(line);
      }
    }
    onRunningChanged: {
      if (running) return;
      root.known = false;
      // Backing off, so one that cannot run does not fill the log.
      restart.interval = Math.min(5000 * 2 ** failures, 300000);
      failures++;
      console.warn(`backlight-watch stopped, starting it again in ${restart.interval / 1000} s`);
      restart.start();
    }
  }

  Timer {
    id: restart

    onTriggered: watcher.running = true
  }
}
