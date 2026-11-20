pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.controls
import qs.common

// The control centre's button: what is worth a glance, as glyphs; the wheel turns the volume and a right click mutes it.
BarButton {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have; set once, so it outlives the screen.
  property string panel: ""
  readonly property var glyphs: {
    const glyphs = [
      Net.vpns.some(vpn => vpn.active) ? Symbols.vpn : "",
      Net.glyph,
      BluetoothDevices.connected.length > 0 ? Symbols.bluetoothConnected : "",
      Microphone.present && Microphone.muted ? Microphone.off : "",
      Volume.present ? Volume.glyph : ""
    ].filter(glyph => glyph !== "");
    // With nothing to show it still opens the centre.
    return glyphs.length > 0 ? glyphs : [Symbols.settings];
  }

  Component.onCompleted: panel = `controls:${screen.name}`

  implicitWidth: icons.implicitWidth + 20
  checked: Panels.active === root.panel
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: button => {
    if (button === Qt.RightButton) Volume.toggleMute();
    else Panels.toggle(root.panel);
  }

  Row {
    id: icons

    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.glyphs

      Glyph {
        required property string modelData

        path: modelData
        size: 18
        color: modelData === Volume.glyph && Volume.muted ? Theme.fgDim : Theme.fg
      }
    }
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

  LazyLoader {
    active: Panels.active === root.panel

    ControlsPanel {
      screen: root.screen
      name: root.panel
      anchorX: root.mapToItem(null, root.width / 2, 0).x
      top: root.Window.height
    }
  }
}
