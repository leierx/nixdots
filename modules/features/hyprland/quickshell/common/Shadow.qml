import QtQuick
import QtQuick.Effects

// libadwaita's window shadow, as a child of the rounded Rectangle it lies under.
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
