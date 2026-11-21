import QtQuick
import QtQuick.Effects

// Shell's one shadow, 0 2px 4px at 20 %; a banner's spreads 2px more.
RectangularShadow {
  property real spreadBy: 0

  anchors.fill: parent
  z: -1
  offset.y: 2
  blur: 4
  spread: spreadBy
  radius: (parent as Rectangle)?.radius ?? 0
  color: Theme.shadowColor
}
