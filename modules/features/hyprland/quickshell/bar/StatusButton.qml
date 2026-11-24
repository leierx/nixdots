pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.controls
import qs.common
import qs.nix
import qs.notifications

// The control centre's button: what is worth a glance, as glyphs; the wheel turns the volume.
BarButton {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have; set once, so it outlives the screen.
  property string panel: ""
  readonly property var glyphs: {
    const glyphs = [
      ...Privacy.kinds.map(kind => ({ name: kind.name, path: kind.glyph, color: Theme.recording })),
      Caffeine.active ? { name: "caffeine", path: Symbols.cup, color: Theme.fg } : null,
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

  // What it draws: the glyphs, and those just gone where they were, fading before the rest close up.
  property var drawn: []

  onGlyphsChanged: {
    const names = new Set(root.glyphs.map(glyph => glyph.name));
    const result = root.glyphs.slice();
    let after = -1;
    for (const old of root.drawn) {
      const at = result.findIndex(glyph => glyph.name === old.name);
      if (at >= 0) {
        after = at;
      } else if (!names.has(old.name)) {
        result.splice(after + 1, 0, Object.assign({}, old, { leaving: true }));
        after++;
      }
    }
    root.drawn = result;
    if (result.some(glyph => glyph.leaving)) gone.restart();
  }

  Timer {
    id: gone

    interval: Theme.popupTime
    onTriggered: root.drawn = root.glyphs
  }

  Component.onCompleted: {
    drawn = glyphs;
    panel = `controls:${screen.name}`;
    loader.active = Panels.active === panel;
  }

  // At least three symbols wide, so it is always an easy target; it eases as one comes or goes.
  implicitWidth: Math.max(icons.implicitWidth, 3 * 16 + 2 * Theme.basePadding) + 2 * Theme.padding

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Theme.popupTime
      easing.type: Easing.OutQuad
    }
  }
  checked: Panels.active === root.panel
  tooltip: "Quick Settings"
  onClicked: Panels.toggle(root.panel)

  // From the right edge, so the glyphs already there hold still as one comes; centred while the button is at its least.
  Row {
    id: icons

    property real inset: Theme.padding + Math.max(0, (root.width - 2 * Theme.padding - icons.implicitWidth) / 2)

    anchors.right: parent.right
    anchors.rightMargin: inset
    anchors.verticalCenter: parent.verticalCenter

    Behavior on inset {
      NumberAnimation {
        duration: Theme.popupTime
        easing.type: Easing.OutQuad
      }
    }
    spacing: Theme.basePadding

    // The others make room for a new one, which fades in on its own: a positioner's add transition cut short leaves its item where it stopped.
    move: Transition {
      NumberAnimation {
        property: "x"
        duration: Theme.popupTime
        easing.type: Easing.OutQuad
      }
    }

    Repeater {
      // Keyed by name, so a symbol that stays keeps its delegate and only the new one arrives.
      model: ScriptModel {
        values: root.drawn
        objectProp: "name"
      }

      Glyph {
        id: glyph

        required property var modelData

        path: modelData.path
        size: 16
        color: modelData.color
        opacity: 0
        Component.onCompleted: arrive.start()
        // Read off its own data: a ScriptModel row that stays in place takes the new object.
        readonly property bool leaving: modelData.leaving ?? false
        onLeavingChanged: if (leaving) {
          arrive.stop();
          leave.start();
        }

        NumberAnimation {
          id: leave

          target: glyph
          property: "opacity"
          to: 0
          duration: Theme.popupTime
          easing.type: Easing.OutQuad
        }

        NumberAnimation {
          id: arrive

          target: glyph
          property: "opacity"
          to: 1
          duration: Theme.popupTime
          easing.type: Easing.OutQuad
        }
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
        font: Theme.numeric
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
