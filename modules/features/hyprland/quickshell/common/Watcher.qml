import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property var command: []
  property var environment: ({})
  property int baseInterval: 5000
  property bool warn: true
  property int failures: 0
  // When it last started: a helper that prints a line and dies still backs off.
  property real started: 0
  readonly property string name: command.join(" ")

  signal line(string text)
  signal stopped()

  property Timer restart: Timer {
    onTriggered: root.process.running = true
  }

  // Started by hand, as the restart does, rather than a binding the first restart would break.
  onCommandChanged: if (root.process && root.command.length > 0 && !root.process.running) root.process.running = true
  Component.onCompleted: if (root.command.length > 0) root.process.running = true

  property Process process: Process {
    command: root.command
    environment: root.environment
    stdout: SplitParser {
      onRead: line => root.line(line)
    }
    onRunningChanged: {
      if (running) {
        root.started = Date.now();
        return;
      }
      root.stopped();
      if (Date.now() - root.started > 60000) root.failures = 0;
      root.restart.interval = Math.min(root.baseInterval * 2 ** root.failures, 300000);
      root.failures++;
      if (root.warn) console.warn(`${root.name} stopped, starting it again in ${root.restart.interval / 1000} s`);
      root.restart.start();
    }
  }
}
