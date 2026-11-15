import QtQuick
import QtQuick.Effects

// libadwaita's shadow under a floating window, for a rounded Rectangle to
// hold as its child: it fills the parent and draws beneath it.
Item {
  id: root

  property real radius: parent.radius

  anchors.fill: parent
  z: -1

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 14
    spread: 5
    color: Qt.rgba(0, 0, 0, 0.15)
  }

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 5
    spread: 2
    color: Qt.rgba(0, 0, 0, 0.1)
  }
}
