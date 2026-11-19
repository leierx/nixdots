pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// The output's volume: the wheel turns it, a right click mutes, a click opens its popup.
Item {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have.
  readonly property string panel: `volume:${screen?.name}`

  visible: Volume.present
  implicitWidth: content.implicitWidth + 12
  implicitHeight: 26

  Rectangle {
    anchors.fill: parent
    radius: Theme.smallRadius
    color: Panels.active === root.panel ? Theme.buttonChecked : area.containsMouse ? Theme.buttonHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }
  }

  Row {
    id: content

    anchors.centerIn: parent
    spacing: 3

    Glyph {
      anchors.verticalCenter: parent.verticalCenter
      path: Volume.glyph
      size: 18
      color: Volume.muted ? Theme.fgDim : Theme.fg
    }

    BarText {
      anchors.verticalCenter: parent.verticalCenter
      text: `${Volume.percent}%`
      color: Volume.muted ? Theme.fgDim : Theme.fg
      font.strikeout: Volume.muted
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) Volume.toggleMute();
      else Panels.toggle(root.panel);
    }
    onWheel: event => {
      const steps = notches.steps(event);
      if (steps !== 0) Volume.step(steps);
    }
  }

  WheelSteps {
    id: notches
  }

  // Under the button, on its own screen.
  LazyLoader {
    active: Panels.active === root.panel

    VolumePopup {
      screen: root.screen
      name: root.panel
      anchorX: root.mapToItem(null, root.width / 2, 0).x
      glyph: Volume.glyph
    }
  }
}
