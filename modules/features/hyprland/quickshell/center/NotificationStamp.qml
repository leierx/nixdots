import QtQuick
import qs.common
import qs.nix
import qs.notifications

// gs MessageHeader's order: the age, expand, close; close without the pointer as the HIG asks of actions.
Item {
  id: root

  required property NotifEntry entry
  property bool closable: false
  property bool expandable: false
  property string pointing: "down"

  signal closed()
  signal toggled()

  // Room for all three on every line, so the ages line up.
  implicitWidth: age.implicitWidth + arrow.width + close.width
  implicitHeight: age.implicitHeight

  NotificationAge {
    id: age

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    entry: root.entry
  }

  // Both overhang the line, so they cost it no height.
  Item {
    id: arrow

    x: age.implicitWidth
    width: 24
    height: parent.height

    IconButton {
      objectName: "expand"
      anchors.centerIn: parent
      visible: root.expandable
      tiny: true
      flat: true
      expander: true
      pointing: root.pointing
      tooltip: root.pointing === "up" ? "Collapse" : "Expand"
      onClicked: root.toggled()
    }
  }

  IconButton {
    id: close

    objectName: "close"
    tiny: true
    flat: true
    glyph: Symbols.close
    tooltip: "Close"
    anchors {
      right: parent.right
      rightMargin: -4
      verticalCenter: parent.verticalCenter
    }
    visible: root.closable
    onClicked: root.closed()
  }
}
