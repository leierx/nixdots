pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.controls
import qs.common
import qs.nix
import qs.notifications

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

  // What it draws, by name: the glyphs, and those just gone where they were, fading before the rest close up.
  property var drawn: []
  // One object per name, kept: a ScriptModel replaces rows in place for as long as the old and new objects differ, past rows whose names do not match (TODO.md), so an unchanged glyph must stay the very same object.
  readonly property var kept: ({})

  function entry(name: string): var {
    return root.kept[name] ?? (root.kept[name] = { name });
  }

  onGlyphsChanged: {
    const result = root.glyphs.map(glyph => root.entry(glyph.name));
    let after = -1;
    for (const old of root.drawn) {
      const at = result.findIndex(glyph => glyph.name === old.name);
      if (at >= 0) {
        after = at;
      } else {
        // Drawn as it last was while it fades.
        const last = root.shown[old.name] ?? {};
        result.splice(after + 1, 0, old.leaving ? old : { name: old.name, leaving: true, path: last.path, color: last.color });
        delete root.kept[old.name];
        after++;
      }
    }
    root.drawn = result;
    if (result.some(glyph => glyph.leaving)) gone.restart();
    root.shown = root.byName(root.glyphs);
  }

  // The glyphs by name, as last shown, for one fading out.
  property var shown: ({})

  function byName(glyphs: var): var {
    const found = {};
    for (const glyph of glyphs) found[glyph.name] = glyph;
    return found;
  }

  Timer {
    id: gone

    interval: Theme.popupTime
    onTriggered: root.drawn = root.glyphs.map(glyph => root.entry(glyph.name))
  }

  Component.onCompleted: {
    drawn = glyphs.map(glyph => entry(glyph.name));
    shown = byName(glyphs);
    panel = `controls:${screen.name}`;
    loader.active = Panels.active === panel;
  }

  // At least three symbols wide, so it is always an easy target; it eases as one comes or goes.
  implicitWidth: Math.max(icons.content, icons.least) + 2 * Theme.padding

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Theme.popupTime
      easing.type: Easing.OutQuad
    }
  }
  checked: Panels.active === root.panel
  tooltip: "Quick Settings"
  onClicked: Panels.toggle(root.panel)

  // Laid from the right edge by hand, which holds still as the button grows leftwards: a glyph keeps its place unless one comes or goes to its left, and only those move, eased. A Row laid them from its left, so each change jumped the others before they slid.
  Item {
    id: icons

    readonly property int step: 16 + Theme.basePadding
    readonly property int count: root.drawn.length
    readonly property real battery: Power.present ? power.implicitWidth : 0
    readonly property real content: count * 16 + battery + Math.max(0, count + (Power.present ? 1 : 0) - 1) * Theme.basePadding
    readonly property real least: 3 * 16 + 2 * Theme.basePadding
    // Centred while the button is at its least.
    readonly property real inset: Theme.padding + Math.max(0, (least - content) / 2)

    anchors.right: parent.right
    width: 0
    height: parent.height

    Repeater {
      // Keyed by name, so a symbol that stays keeps its delegate and only the new one arrives.
      model: ScriptModel {
        values: root.drawn
        objectProp: "name"
      }

      Glyph {
        id: glyph

        required property var modelData
        // From the list itself rather than the delegate's index, which updates apart from the count.
        readonly property int after: root.drawn.length - 1 - root.drawn.findIndex(other => other.name === glyph.modelData.name)

        x: -(icons.inset + (Power.present ? icons.battery + Theme.basePadding : 0) + glyph.after * icons.step + 16)
        y: (icons.height - height) / 2
        // The glyph as it is now, or as it was while it fades out.
        readonly property var look: glyph.leaving ? glyph.modelData : root.glyphs.find(other => other.name === glyph.modelData.name) ?? glyph.modelData

        path: glyph.look.path ?? ""
        size: 16
        color: glyph.look.color ?? Theme.fg
        opacity: 0
        Component.onCompleted: arrive.start()
        // Read off its own data: a ScriptModel row that stays in place takes the new object.
        readonly property bool leaving: modelData.leaving ?? false
        onLeavingChanged: if (leaving) {
          arrive.stop();
          leave.start();
        } else {
          leave.stop();
          arrive.restart();
        }

        Behavior on x {
          NumberAnimation {
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }
        }

        NumberAnimation {
          id: leave

          target: glyph
          property: "opacity"
          to: 0
          duration: Theme.popupTime
          easing.type: Easing.OutQuad
        }

        // Once those to its left have made half the room, so it never shows over one still moving.
        SequentialAnimation {
          id: arrive

          PauseAnimation {
            duration: Theme.popupTime / 2
          }

          NumberAnimation {
            target: glyph
            property: "opacity"
            to: 1
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }
        }
      }
    }

    Row {
      id: power

      x: -(icons.inset + width)
      anchors.verticalCenter: parent.verticalCenter
      visible: Power.present
      spacing: 3

      Behavior on x {
        NumberAnimation {
          duration: Theme.popupTime
          easing.type: Easing.OutQuad
        }
      }

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
