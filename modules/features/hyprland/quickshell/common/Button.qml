import QtQuick

Rectangle {
  id: root

  property alias text: label.text
  property alias font: label.font
  property bool flat: false
  // Held down, as a flat button is while what it opens is open.
  property bool checked: false
  property bool expander: false
  property bool open: false
  property real padding: 17

  readonly property bool hovered: area.containsMouse
  readonly property real contentWidth: (label.visible ? label.implicitWidth : 0) + (arrow.visible ? arrow.width : 0) + (label.visible && arrow.visible ? row.spacing : 0)

  signal clicked()

  implicitWidth: Math.max(implicitHeight, contentWidth + 2 * padding)
  implicitHeight: 34
  radius: Theme.buttonRadius
  color: area.pressed || checked ? Theme.buttonHover : area.containsMouse ? (flat ? Theme.button : Theme.buttonHover) : flat ? "transparent" : Theme.button

  Row {
    id: row

    anchors.centerIn: parent
    spacing: 6

    Text {
      id: label

      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, root.width - 2 * root.padding - (arrow.visible ? arrow.width + row.spacing : 0))
      visible: text !== ""
      color: Theme.fg
      elide: Text.ElideRight
      font: Theme.heading
    }

    ExpanderArrow {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      visible: root.expander
      open: root.open
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
