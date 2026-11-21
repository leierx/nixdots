pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.controls
import qs.common
import qs.nix
import qs.notifications

// The control centre's button: what is worth a glance, as glyphs; the wheel turns the volume and a right click mutes it.
BarButton {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have; set once, so it outlives the screen.
  property string panel: ""
  readonly property var glyphs: {
    const glyphs = [
      ...Privacy.kinds.map(kind => ({ name: kind.name, path: kind.glyph, color: Theme.recording })),
      Notifs.dnd ? { name: "dnd", path: Symbols.dnd, color: Theme.fg } : Notifs.unchecked > 0 ? { name: "bell", path: Symbols.bell, color: Theme.bell } : null,
      Net.vpns.some(vpn => vpn.active) ? { name: "vpn", path: Symbols.vpn, color: Theme.fg } : null,
      Net.glyph !== "" ? { name: "network", path: Net.glyph, color: Theme.fg } : null,
      BluetoothDevices.connected.length > 0 ? { name: "bluetooth", path: Symbols.bluetoothConnected, color: Theme.fg } : null,
      Microphone.present && Microphone.muted ? { name: "microphone", path: Symbols.micOff, color: Theme.fg } : null,
      Volume.present ? { name: "volume", path: Volume.glyph, color: Volume.muted ? Theme.fgDim : Theme.fg } : null
    ].filter(glyph => glyph !== null);
    // With nothing to show it still opens the centre.
    return glyphs.length > 0 || Power.present ? glyphs : [{ name: "settings", path: Symbols.settings, color: Theme.fg }];
  }

  Component.onCompleted: {
    panel = `controls:${screen.name}`;
    loader.active = Panels.active === panel;
  }

  implicitWidth: icons.implicitWidth + 2 * Theme.padding
  checked: Panels.active === root.panel
  tooltip: "Quick Settings"
  onClicked: Panels.toggle(root.panel)

  Row {
    id: icons

    anchors.centerIn: parent
    spacing: Theme.basePadding

    Repeater {
      model: root.glyphs

      Glyph {
        required property var modelData

        path: modelData.path
        size: 16
        color: modelData.color
      }
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      visible: Power.present
      spacing: 3

      BatteryGlyph {
        anchors.verticalCenter: parent.verticalCenter
        level: Power.percent / 100
        charging: Power.charging
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Power.percent
        color: Theme.fg
        font: Theme.numericHeading
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

  // Unloaded once it has faded out.
  LazyLoader {
    id: loader

    ControlsPanel {
      screen: root.screen
      name: root.panel
      anchorX: root.mapToItem(null, root.width / 2, 0).x
      top: root.Window.height
      onHidden: loader.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active === root.panel) loader.active = true;
    }
  }
}
