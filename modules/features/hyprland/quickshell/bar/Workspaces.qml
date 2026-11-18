pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

Item {
  id: root

  required property HyprlandMonitor monitor
  // Not monitor.focused: Quickshell binds it only on monitors added after it started.
  readonly property bool focused: monitor !== null && Hyprland.focusedMonitor === monitor
  readonly property var own: {
    if (!monitor || monitor.id < 0) return [];
    const first = monitor.id * WorkspaceOwners.perMonitor + 1;
    return Array.from({ length: WorkspaceOwners.perMonitor }, (_, i) => first + i);
  }
  readonly property var foreign: !monitor ? [] : Hyprland.workspaces.values
    .filter(ws => ws.monitor === monitor && !ws.name.startsWith("special:") && !own.includes(ws.id))
    .sort((a, b) => (b.id > 0) - (a.id > 0) || a.id - b.id || a.name.localeCompare(b.name))
  // As the bar shows them, which is also the order the wheel goes through.
  readonly property var targets: [...own.map(id => String(id)), ...foreign.map(ws => ws.id > 0 ? String(ws.id) : `name:${ws.name}`)]
  readonly property string shownTarget: {
    const ws = monitor?.activeWorkspace;
    return !ws ? "" : ws.id > 0 ? String(ws.id) : `name:${ws.name}`;
  }
  function go(target: string): void {
    Panels.close();
    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(target)} })`);
  }

  // Stopping at the ends.
  function scroll(steps: int): void {
    if (steps === 0) return;
    const at = targets.indexOf(shownTarget);
    const next = Math.max(0, Math.min(targets.length - 1, (at < 0 ? 0 : at) - steps));
    if (targets[next] !== shownTarget) go(targets[next]);
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  WheelSteps {
    id: notches
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => root.scroll(notches.steps(event))
  }

  // Yours a bare number, a squircle under it only while shown (faintly) or under the pointer; another monitor's an outlined pill named after it (DP2-1).
  component Workspace: Rectangle {
    id: button

    property HyprlandWorkspace workspace: null
    property string target: ""
    property string label: ""
    property bool mine: true
    readonly property bool shown: workspace !== null && root.monitor?.activeWorkspace === workspace
    readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
    readonly property bool urgent: workspace?.urgent ?? false
    readonly property bool filled: shown && !mine
    // A step darker on a monitor without focus.
    readonly property color bright: root.focused ? Theme.fg : Theme.fgDim

    anchors.verticalCenter: parent?.verticalCenter
    width: Math.max(mine ? 26 : 20, text.implicitWidth + 14)
    height: mine ? 26 : 20
    radius: mine ? 8 : 10
    color: {
      if (filled) return bright;
      if (shown) return area.containsMouse ? Theme.buttonChecked : root.focused ? Theme.buttonHover : Theme.button;
      if (area.containsMouse) return Theme.buttonHover;
      return "transparent";
    }
    border.width: mine ? 0 : 1
    border.color: Theme.border

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }

    // Played through on the press rather than held while pressed: after a switch the release may not arrive until the pointer moves.
    SequentialAnimation {
      id: tap

      NumberAnimation {
        target: button
        property: "scale"
        to: 0.86
        duration: 70
        easing.type: Easing.OutQuad
      }

      NumberAnimation {
        target: button
        property: "scale"
        to: 1
        duration: 160
        easing.type: Easing.OutBack
      }
    }

    Text {
      id: text

      anchors.centerIn: parent
      text: button.label
      color: {
        if (button.filled) return Theme.panel;
        if (button.urgent) return Theme.destructive;
        if (area.containsMouse) return Theme.fg;
        if (button.shown) return button.bright;
        if (button.occupied) return root.focused ? Theme.fgDim : Theme.fgMuted;
        return Theme.fgFaint;
      }
      font: Qt.font({ family: Theme.body.family, pointSize: button.mine ? 10 : 8, weight: button.shown && button.mine ? Font.ExtraBold : Font.Bold })
    }

    // As tall as the bar and across the gaps either side.
    MouseArea {
      id: area

      anchors.centerIn: parent
      width: parent.width + (button.mine ? 2 : 4)
      height: root.height
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      // On press, which feels quicker than a click.
      onPressed: {
        tap.restart();
        root.go(button.target);
      }
    }
  }

  Row {
    id: row

    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Repeater {
        model: root.own

        Workspace {
          required property int modelData

          target: String(modelData)
          label: String(WorkspaceOwners.index(modelData))
          workspace: Hyprland.workspaces.values.find(ws => ws.id === modelData) ?? null
        }
      }
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Repeater {
        model: root.foreign

        Workspace {
          required property HyprlandWorkspace modelData

          mine: false
          workspace: modelData
          target: modelData?.id > 0 ? String(modelData.id) : `name:${modelData?.name}`
          label: modelData ? WorkspaceOwners.label(modelData, root.monitor) : ""
        }
      }
    }
  }
}
