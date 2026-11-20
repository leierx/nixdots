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
  // Material Symbols' bolt, filled
  readonly property string bolt: "M360-360H236q-24 0-35.5-21.5T203-423l299-430q10-14 26-19.5t33 .5q17 6 25 21t6 32l-32 259h155q26 0 36.5 23t-6.5 43L416-100q-11 13-27 17t-31-3q-15-7-23.5-21.5T328-139l32-221Z"

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
          duration: 400
          easing.type: Easing.OutCubic
        }
      }
    }

    Glyph {
      anchors.centerIn: parent
      visible: root.charging
      path: root.bolt
      size: Math.round(root.size * 0.62)
      color: Theme.panel
    }
  }
}
