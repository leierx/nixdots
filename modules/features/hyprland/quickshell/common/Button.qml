import QtQuick

// Shell's %button: 8 px or a pill, bold, the foreground's shades; flat on a surface of its own, suggested in the accent, destructive in red.
Rectangle {
  id: root

  property alias text: label.text
  property alias font: label.font
  property alias acceptedButtons: area.acceptedButtons
  // A Symbols path, before the text.
  property string glyph: ""
  property int glyphSize: 16
  property bool flat: false
  property bool suggested: false
  property bool destructive: false
  property bool pill: false
  // Held down, as a button is while what it opens is open.
  property bool checked: false
  // An ExpanderArrow after the text, pointing as it says.
  property bool expander: false
  property string pointing: "down"
  property real padding: 24
  // What an icon alone does, shown as the pointer rests on it and read out as its name.
  property string tooltip: ""
  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: area.containsMouse
  property bool pressed: area.pressed

  readonly property bool filled: suggested || destructive
  readonly property color fillBg: suggested ? Theme.accentBg : Theme.destructiveBg
  readonly property color fillHover: suggested ? Theme.accentHover : Theme.destructiveHover
  readonly property color fillActive: suggested ? Theme.accentActive : Theme.destructiveActive
  property color foreground: filled ? Theme.accentFg : Theme.fg
  readonly property var parts: [glyph !== "" ? glyphSize : -1, label.text !== "" ? label.implicitWidth : -1, expander ? arrow.width : -1].filter(width => width >= 0)
  readonly property real contentWidth: parts.reduce((sum, width) => sum + width, 0) + Math.max(0, parts.length - 1) * row.spacing

  signal clicked(int button)

  implicitWidth: Math.max(implicitHeight, contentWidth + 2 * padding)
  implicitHeight: Theme.buttonHeight
  radius: pill ? height / 2 : Theme.baseRadius
  // libadwaita's --disabled-opacity, as the panels hold app-like content.
  opacity: enabled ? 1 : 0.5
  color: {
    if (filled) {
      if (pressed || checked) return fillActive;
      return hovered ? fillHover : fillBg;
    }
    if (flat) {
      if (pressed || checked) return Theme.buttonHoverBg;
      return hovered ? Theme.buttonBg : "transparent";
    }
    if (pressed) return Theme.buttonActiveBg;
    if (checked) return hovered ? Theme.buttonCheckedHoverBg : Theme.buttonCheckedBg;
    return hovered ? Theme.buttonHoverBg : Theme.buttonBg;
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.quickTime
    }
  }

  Row {
    id: row

    anchors.centerIn: parent
    spacing: Theme.basePadding

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
      color: root.foreground
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    // A disabled ancestor leaves its own reading true.
    enabled: root.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: Tooltips.cancel(root)
    onClicked: mouse => root.clicked(mouse.button)
  }

  TooltipArea {
    text: root.tooltip
  }

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked(Qt.LeftButton)
  Keys.onSpacePressed: root.clicked(Qt.LeftButton)

  FocusRing {
    corner: root.radius
    on: root.activeFocus
  }

  Accessible.name: root.tooltip || label.text
}
