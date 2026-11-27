import QtQuick
import Quickshell.Io

// Stops a process once it has run this long: one that never answers would hold its single run, and what waits on it, for good.
Timer {
  id: root

  required property Process process

  signal expired()

  interval: 10000
  onTriggered: {
    root.expired();
    root.process.running = false;
  }

  // Counted from each start: a run started from the last one's exit handler reads running throughout, so a binding would keep the first run's count.
  property Connections runs: Connections {
    target: root.process

    function onStarted(): void {
      if (root.interval > 0) root.restart();
    }
    function onRunningChanged(): void {
      if (!root.process.running) root.stop();
    }
  }
}
