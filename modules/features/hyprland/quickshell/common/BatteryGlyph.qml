import QtQuick

// GNOME's battery: an upright cell filled to its charge, green, yellow from 25 %, red from 10 %, with a bolt while charging.
Item {
  id: root

  property real level: 1
  property bool charging: false
  property int size: 18
  property color color: Theme.fg
  readonly property color fill: charging || level > 0.25 ? Theme.success : level > 0.1 ? Theme.warning : Theme.destructive
  readonly property real line: Math.max(1.5, size / 11)

  implicitWidth: Math.round(size * 0.56)
  implicitHeight: size

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.size * 0.04
    width: root.size * 0.22
    height: root.size * 0.12
    radius: height / 3
    color: root.color
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.size * 0.13
    width: root.size * 0.52
    height: root.size * 0.83
    radius: root.size * 0.12
    color: "transparent"
    border.width: root.line
    border.color: root.color

    Rectangle {
      readonly property real inset: root.line * 1.7

      x: inset
      width: parent.width - 2 * inset
      height: Math.max(root.line, (parent.height - 2 * inset) * Math.max(0, Math.min(1, root.level)))
      y: parent.height - inset - height
      radius: root.size * 0.04
      color: root.fill

      Behavior on height {
        NumberAnimation {
          duration: Theme.settle
          easing.type: Easing.OutCubic
        }
      }
    }

    Glyph {
      anchors.centerIn: parent
      visible: root.charging
      path: Symbols.bolt
      size: Math.round(root.size * 0.62)
      color: Theme.panel
    }
  }
}
