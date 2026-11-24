import QtQuick
import qs.common
import qs.nix
import qs.notifications

Item {
  id: root

  required property NotifEntry entry
  property bool closable: false
  property bool expandable: false
  property string pointing: "down"
  // The arrow's room kept with no arrow, so the ages of a group's lines line up.
  property bool reserved: true

  signal closed()
  signal toggled()

  // The close overhangs the right edge by 4, so its symbol lines up with the card's padding; the arrow is as far from the age as from the close.
  implicitWidth: age.implicitWidth + 4 + arrow.width + close.width - 4
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

    x: age.implicitWidth + 4
    width: root.expandable || root.reserved ? 24 : 0
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
