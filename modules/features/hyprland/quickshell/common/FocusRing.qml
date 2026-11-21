import QtQuick

// The ring round what the keyboard is on, 2 px of the accent just inside its edge, where no scrolling list clips it; shown once keys have moved it, as GTK shows it.
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
