import QtQuick

Rectangle {
  // The radius of what it rings.
  property real corner: 0
  property bool on: false

  anchors.fill: parent

  radius: corner
  color: "transparent"
  border.width: 2
  border.color: Theme.focusRing
  visible: on && Panels.keyboard
}
