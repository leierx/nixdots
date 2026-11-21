pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's keyboards' lock state, read when Hyprland says the Caps Lock key went up (quickshell.nix).
Singleton {
  id: root

  property bool on: false
  property bool known: false
  property bool again: false

  signal toggled()

  function query(): void {
    if (devices.running) root.again = true;
    else devices.running = true;
  }

  function read(text: string): void {
    let keyboards;
    try {
      keyboards = JSON.parse(text).keyboards ?? [];
    } catch (error) {
      console.warn(`hyprctl devices: ${error}`);
      return;
    }
    // Each keyboard has its own lock; the one in use is Hyprland's main one.
    const main = keyboards.find(keyboard => keyboard.main);
    const on = main ? main.capsLock : keyboards.some(keyboard => keyboard.capsLock);
    const changed = root.known && on !== root.on;
    root.on = on;
    root.known = true;
    if (changed) root.toggled();
  }

  Component.onCompleted: query()

  Process {
    id: devices

    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: root.read(text)
    }
    onRunningChanged: {
      if (running || !root.again) return;
      root.again = false;
      running = true;
    }
  }

  // The key event comes before the keyboard's new state, so a second look follows the first.
  Timer {
    id: later

    interval: 150
    onTriggered: root.query()
  }

  GlobalShortcut {
    name: "caps-lock"
    onPressed: {
      root.query();
      later.restart();
    }
    onReleased: {
      root.query();
      later.restart();
    }
  }
}
