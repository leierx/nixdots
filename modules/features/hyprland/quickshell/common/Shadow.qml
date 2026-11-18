import QtQuick
import QtQuick.Effects

Item {
  id: root

  property real radius: (parent as Rectangle)?.radius ?? 0

  anchors.fill: parent
  z: -1

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 14
    spread: 5
    color: Theme.shadow
  }

  RectangularShadow {
    anchors.fill: parent
    radius: root.radius
    blur: 5
    spread: 2
    color: Theme.shadowTight
  }
}
