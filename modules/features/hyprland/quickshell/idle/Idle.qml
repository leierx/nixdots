pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

Scope {
  id: root

  property real level: 0
  // hyprlock's screenshot takes in the dim, so it stays put from the lock command asking until the session is locked.
  property bool held: false
  property bool locked: false
  // Apart from the level, so the windows are not looked at again every frame of the fade.
  readonly property bool dimmed: level > 0

  NumberAnimation {
    id: dimming

    target: root
    property: "level"
    easing.type: Easing.InQuad
  }

  // A fade whose lock or cancel never came (hypridle restarted mid-fade) lifts, rather than leave the screens dark.
  Timer {
    interval: 10000
    running: root.dimmed && !dimming.running && !root.held && !root.locked
    onTriggered: root.level = 0
  }

  IpcHandler {
    target: "idle"

    function fade(seconds: int, depth: real): void {
      if (root.held || root.locked || dimming.running || root.level > 0) return;
      dimming.to = Math.max(0, Math.min(1, depth));
      dimming.duration = seconds * 1000;
      dimming.start();
    }

    function cancel(): void {
      if (root.held) return;
      dimming.stop();
      root.level = 0;
    }

    function hold(): real {
      dimming.stop();
      root.held = true;
      return root.level;
    }

    function locked(): void {
      root.held = false;
      root.locked = true;
      dimming.stop();
      root.level = 0;
    }

    function unlocked(): void {
      root.held = false;
      root.locked = false;
      dimming.stop();
      root.level = 0;
    }
  }

  Variants {
    model: root.dimmed ? Screens.real : []

    PanelWindow {
      required property ShellScreen modelData

      screen: modelData
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      // Input goes through to hypridle, whose resume cancels the fade.
      mask: Region {}

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell:idle"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        anchors.fill: parent
        color: Theme.idle
        opacity: root.level
      }
    }
  }
}
