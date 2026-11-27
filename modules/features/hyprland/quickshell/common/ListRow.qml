import QtQuick

Rectangle {
  id: root

  property string glyph: ""
  property color glyphColor: Theme.fg
  property string title: ""
  property bool strong: false
  // Whether a click does something, for the pointer.
  property bool acts: true
  property alias areaName: area.objectName
  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: area.containsMouse
  property bool pressed: area.pressed
  // A row with the keyboard takes the grey fill rather than a ring, as menus mark it.
  property bool selected: activeFocus && Panels.keyboard
  default property alias trailing: end.data

  signal clicked()

  implicitHeight: Theme.menuRowHeight
  radius: Theme.menuItemRadius
  opacity: enabled ? 1 : 0.5

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.quickTime
      easing.type: Easing.OutQuad
    }
  }

  // Kept while it has the keyboard: Qt refuses to take it back from the focused item, and warns.
  activeFocusOnTab: acts || activeFocus
  Keys.onReturnPressed: event => {
    if (!event.isAutoRepeat) root.clicked();
  }
  Keys.onSpacePressed: event => {
    if (!event.isAutoRepeat) root.clicked();
  }
  // The keyboard's row snaps, as keyboard selection never animates; hover and a press ease over it.
  color: acts && enabled && selected ? Theme.selectedBg : "transparent"

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: {
      if (!root.acts || !root.enabled) return "transparent";
      if (root.pressed) return Theme.menuActiveBg;
      return root.hovered && !root.selected ? Theme.menuHoverBg : "transparent";
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.quickTime
        easing.type: Easing.OutQuad
      }
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
    x: Theme.padding
    anchors.verticalCenter: parent.verticalCenter
    visible: root.glyph !== ""
    path: root.glyph
    size: 16
    color: root.glyphColor
  }

  Text {
    x: Theme.padding + 16 + Theme.basePadding
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, parent.width - x - Theme.padding - (end.width > 0 ? end.width + Theme.basePadding : 0))
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
    anchors.rightMargin: Theme.padding
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.basePadding
  }
}
