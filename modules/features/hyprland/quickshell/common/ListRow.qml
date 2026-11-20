import QtQuick

// A row of a list in a panel: a 20 px symbol in a column of its own, the name beside it, and what it says on the right.
Rectangle {
  id: root

  property string glyph: ""
  property color glyphColor: Theme.fg
  property string title: ""
  property bool strong: false
  // Whether a click does something, for the pointer.
  property bool acts: true
  property alias areaName: area.objectName
  readonly property alias hovered: area.containsMouse
  default property alias trailing: end.data

  signal clicked()

  implicitHeight: 36
  radius: Theme.smallRadius
  color: area.containsMouse && area.enabled && acts ? Theme.hover : "transparent"

  Behavior on color {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    // A disabled ancestor leaves its own reading true.
    enabled: root.enabled
    cursorShape: enabled && root.acts ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }

  Glyph {
    x: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: root.glyph !== ""
    path: root.glyph
    size: 20
    color: root.glyphColor
  }

  Text {
    x: 40
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, parent.width - x - 10 - (end.width > 0 ? end.width + 10 : 0))
    text: root.title
    textFormat: Text.PlainText
    maximumLineCount: 1
    elide: Text.ElideRight
    color: Theme.fg
    font: root.strong ? Theme.heading : Theme.body
  }

  Row {
    id: end

    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8
  }
}
