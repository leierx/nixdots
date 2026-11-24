import QtQuick
import qs.common

Rectangle {
  id: root

  required property NotifEntry entry

  implicitHeight: 4
  radius: height / 2
  color: Theme.troughBg

  Rectangle {
    width: parent.width * Math.max(0, Math.min(100, root.entry.progress ?? 0)) / 100
    height: parent.height
    radius: parent.radius
    color: Theme.accentBg
  }
}
