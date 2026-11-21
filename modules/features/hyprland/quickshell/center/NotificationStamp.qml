import QtQuick
import qs.common
import qs.notifications

// The age, and after it the close button, there without the pointer as the HIG asks of actions.
Item {
  id: root

  required property NotifEntry entry
  property bool closable: false

  signal closed()

  // Room for it on every line, so the ages line up.
  implicitWidth: age.implicitWidth + close.width
  implicitHeight: age.implicitHeight

  NotificationAge {
    id: age

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    entry: root.entry
  }

  // Overhanging the line, so it costs the line no height.
  IconButton {
    id: close

    objectName: "close"
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
