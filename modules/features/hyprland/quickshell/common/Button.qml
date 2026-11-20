import QtQuick

Rectangle {
  id: root

  property alias text: label.text
  property alias font: label.font
  property alias acceptedButtons: area.acceptedButtons
  // A Material Symbols path, before the text.
  property string glyph: ""
  property int glyphSize: 18
  property color foreground: Theme.fg
  property bool flat: false
  // Held down, as a flat button is while what it opens is open.
  property bool checked: false
  // An ExpanderArrow after the text, pointing as it says.
  property bool expander: false
  property string pointing: "down"
  property real padding: 17

  readonly property bool hovered: area.containsMouse
  readonly property var parts: [glyph !== "" ? glyphSize : -1, label.text !== "" ? label.implicitWidth : -1, expander ? arrow.width : -1].filter(width => width >= 0)
  readonly property real contentWidth: parts.reduce((sum, width) => sum + width, 0) + Math.max(0, parts.length - 1) * row.spacing

  signal clicked(int button)

  implicitWidth: Math.max(implicitHeight, contentWidth + 2 * padding)
  implicitHeight: 34
  radius: Theme.buttonRadius
  color: {
    if (area.pressed || checked) return Theme.buttonChecked;
    if (area.containsMouse) return Theme.buttonHover;
    return flat ? "transparent" : Theme.button;
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Row {
    id: row

    anchors.centerIn: parent
    spacing: 6

    Glyph {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.glyph !== ""
      path: root.glyph
      size: root.glyphSize
      color: root.foreground
    }

    Text {
      id: label

      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, root.width - 2 * root.padding - (root.glyph !== "" ? root.glyphSize + row.spacing : 0) - (arrow.visible ? arrow.width + row.spacing : 0))
      visible: text !== ""
      color: root.foreground
      elide: Text.ElideRight
      font: Theme.heading
    }

    ExpanderArrow {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      visible: root.expander
      pointing: root.pointing
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    // A disabled ancestor leaves its own reading true.
    enabled: root.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: mouse => root.clicked(mouse.button)
  }
}
