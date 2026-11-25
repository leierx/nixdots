import QtQuick
import Quickshell.Io

// Stops a process once it has run this long: one that never answers would hold its single run, and what waits on it, for good.
Timer {
  id: root

  required property Process process

  signal expired()

  interval: 10000
  running: process.running && interval > 0
  onTriggered: {
    root.expired();
    root.process.running = false;
  }
}
