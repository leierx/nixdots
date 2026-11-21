pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The caffeine user unit (quickshell.nix), which holds logind's idle inhibitor for as long as it runs: the control centre's Caffeine.
Singleton {
  id: root

  readonly property string unit: "caffeine.service"
  property bool active: false
  // The control centre is open: checked more often then, for a change made elsewhere showing as it is looked at.
  property bool watched: false

  function toggle(): void {
    root.set(!root.active);
  }

  function set(on: bool): void {
    if (change.running) return;
    root.active = on;
    change.command = ["systemctl", "--user", on ? "start" : "stop", root.unit];
    change.running = true;
  }

  function refresh(): void {
    if (!change.running && !state.running) state.running = true;
  }

  IpcHandler {
    target: "caffeine"

    function toggle(): void {
      Caffeine.toggle();
    }

    function set(on: bool): void {
      Caffeine.set(on);
    }

    function active(): bool {
      return Caffeine.active;
    }
  }

  Component.onCompleted: refresh()
  onWatchedChanged: if (watched) refresh()

  Command {
    id: change

    name: "Caffeine"
    onDone: root.refresh()
    onFailed: root.refresh()
  }

  // is-active exits non-zero for any state but active, so this is a Process and not a Command.
  Process {
    id: state

    command: ["systemctl", "--user", "is-active", root.unit]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!change.running) root.active = ["active", "activating", "reloading"].includes(text.trim());
      }
    }
  }

  Timer {
    // The status button shows it always, and a unit can stop by itself (logind refusing the inhibitor, say).
    interval: root.watched ? 2000 : 5000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }
}
