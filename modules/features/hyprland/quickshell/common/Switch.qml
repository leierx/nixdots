import QtQuick

// Shell's .toggle-switch: 46 by 26, a 20 px knob 3 px in.
Rectangle {
  id: toggle

  property bool checked: false
  // Alone, rather than in a row that takes the keyboard for it.
  property bool focusable: false
  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: area.containsMouse

  signal clicked()

  implicitWidth: 46
  implicitHeight: 26
  radius: height / 2
  opacity: enabled ? 1 : 0.5
  activeFocusOnTab: focusable && enabled
  Keys.onReturnPressed: toggle.clicked()
  Keys.onSpacePressed: toggle.clicked()
  color: {
    if (checked) return hovered ? Theme.accentHover : Theme.accentBg;
    return hovered ? Theme.switchHoverBg : Theme.switchBg;
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.quickTime
    }
  }

  Rectangle {
    x: toggle.checked ? toggle.width - width - 3 : 3
    anchors.verticalCenter: parent.verticalCenter
    width: 20
    height: 20
    radius: width / 2
    color: toggle.checked ? Theme.fg : Theme.switchKnob

    Behavior on x {
      NumberAnimation {
        duration: Theme.quickTime
        easing.type: Easing.OutQuad
      }
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    enabled: toggle.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: toggle.clicked()
  }

  FocusRing {
    corner: toggle.radius
    on: toggle.activeFocus
  }
}
