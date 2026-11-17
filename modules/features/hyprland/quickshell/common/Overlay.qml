import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property string name
  // A click anywhere but on it closes the panel.
  property Item card: null

  // No screen is set, so Hyprland opens it on the focused monitor.
  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  // Cover the bar rather than being pushed aside by it.
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  // Hyprland closes it with its monitor; still open in Panels, the next toggle would only close it.
  onClosed: if (Panels.active === root.name) Panels.close()

  MouseArea {
    anchors.fill: parent
    onClicked: mouse => {
      if (!root.card?.contains(mapToItem(root.card, mouse.x, mouse.y))) Panels.close();
    }
  }
}
