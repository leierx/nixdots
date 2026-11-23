import QtQuick
import Quickshell
import Quickshell.Io

// A long-lived command that starts again when it stops, backing off while it keeps failing; a line resets the wait.
QtObject {
  id: root

  property var command: []
  property var environment: ({})
  property int baseInterval: 5000
  property bool warn: true
  property int failures: 0
  readonly property string name: command.join(" ")

  signal line(string text)
  signal stopped()

  property Timer restart: Timer {
    onTriggered: root.process.running = true
  }

  property Process process: Process {
    running: root.command.length > 0
    command: root.command
    environment: root.environment
    stdout: SplitParser {
      onRead: line => {
        root.failures = 0;
        root.line(line);
      }
    }
    onRunningChanged: {
      if (running) return;
      root.stopped();
      root.restart.interval = Math.min(root.baseInterval * 2 ** root.failures, 300000);
      root.failures++;
      if (root.warn) console.warn(`${root.name} stopped, starting it again in ${root.restart.interval / 1000} s`);
      root.restart.start();
    }
  }
}
