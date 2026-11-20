pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// The output's volume: the wheel turns it, a right click mutes, a click opens its popup.
BarButton {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have; set once, so it outlives the screen.
  property string panel: ""

  Component.onCompleted: panel = `volume:${screen.name}`

  visible: Volume.present
  checked: Panels.active === root.panel
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  glyph: Volume.glyph
  foreground: Volume.muted ? Theme.fgDim : Theme.fg
  text: `${Volume.percent}%`
  font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: Font.Medium, strikeout: Volume.muted })
  onClicked: button => {
    if (button === Qt.RightButton) Volume.toggleMute();
    else Panels.toggle(root.panel);
  }

  WheelSteps {
    id: notches
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      const steps = notches.steps(event);
      if (steps !== 0) Volume.step(steps);
    }
  }

  // Under the button, on its own screen.
  LazyLoader {
    active: Panels.active === root.panel

    VolumePopup {
      screen: root.screen
      name: root.panel
      anchorX: root.mapToItem(null, root.width / 2, 0).x
      top: root.Window.height
    }
  }
}
