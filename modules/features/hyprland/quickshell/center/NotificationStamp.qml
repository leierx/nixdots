import QtQuick
import qs.common
import qs.nix
import qs.notifications

// The age, the expander and the close button, in gs MessageHeader's order; the close there without the pointer as the HIG asks of actions.
Item {
  id: root

  required property NotifEntry entry
  property bool closable: false
  property bool expandable: false
  property string pointing: "down"

  signal closed()

  // Room for all three on every line, so the ages line up.
  implicitWidth: age.implicitWidth + arrow.width + close.width
  implicitHeight: age.implicitHeight

  NotificationAge {
    id: age

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    entry: root.entry
  }

  Item {
    id: arrow

    x: age.implicitWidth
    width: 24
    height: parent.height

    ExpanderArrow {
      anchors.centerIn: parent
      visible: root.expandable
      pointing: root.pointing
    }
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
    tooltip: "Dismiss"
    anchors {
      right: parent.right
      rightMargin: -4
      verticalCenter: parent.verticalCenter
    }
    visible: root.closable
    onClicked: root.closed()
  }
}
