pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// The screens going dark before hyprlock: hypridle starts it and, on any input, cancels it, so its timers stay the only ones.
Scope {
  id: root

  property real level: 0

  NumberAnimation {
    id: dimming

    target: root
    property: "level"
    to: 1
    easing.type: Easing.InQuad
  }

  IpcHandler {
    target: "idle"

    function fade(seconds: int): void {
      if (dimming.running || root.level > 0) return;
      dimming.duration = seconds * 1000;
      dimming.start();
    }

    function cancel(): void {
      dimming.stop();
      root.level = 0;
    }
  }

  Variants {
    model: root.level > 0 ? Screens.real : []

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
