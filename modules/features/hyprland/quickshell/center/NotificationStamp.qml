import QtQuick
import qs.common
import qs.notifications

Item {
  id: root

  required property NotifEntry entry
  property bool closable: false

  signal closed()

  implicitWidth: age.implicitWidth
  implicitHeight: age.implicitHeight

  NotificationAge {
    id: age

    anchors.right: parent.right
    opacity: root.closable ? 0 : 1
    entry: root.entry
  }

  // In the age's place, so the cross costs the line no room.
  IconButton {
    implicitWidth: 24
    implicitHeight: 24
    flat: true
    glyph: Symbols.close
    glyphSize: 16
    anchors {
      right: parent.right
      rightMargin: -4
      verticalCenter: parent.verticalCenter
    }
    visible: root.closable
    onClicked: root.closed()
  }
}
