pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

// Under the windows, so a click on bare desktop closes the open panel and one on a window reaches it; always mapped, as windows made as a panel opened slowed its taking the keyboard.
Variants {
  model: Screens.real

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
    mask: Panels.active !== "" ? null : nothing

    Region {
      id: nothing
    }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:click-away"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onPressed: Panels.close()
    }
  }
}
