import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// No screen is set, so Hyprland opens it on the focused monitor.
PanelWindow {
  id: root

  // The card's top sits where content this tall is centred, so the search field stays put as the list shortens.
  required property real fullHeight
  property int cardWidth: 640
  readonly property int padding: 8

  default property alias content: body.data

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
  WlrLayershell.namespace: "quickshell:launcher"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((parent.height - root.fullHeight) / 2) - root.padding
    width: root.cardWidth
    height: body.implicitHeight + root.padding * 2
    radius: Theme.windowRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline

    // Keys the search field does not use travel up to here.
    Keys.onEscapePressed: Panels.close()

    // Keeps clicks on the card's padding from closing the picker.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: body

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.padding
      }
    }
  }
}
