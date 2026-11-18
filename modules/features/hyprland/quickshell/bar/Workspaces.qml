pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

Row {
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
  // Per monitor that owns them, by its name; named ones each on their own.
  readonly property var groups: {
    const groups = [];
    for (const ws of foreign) {
      const name = ws.id > 0 ? WorkspaceOwners.foreignLabel(ws.id).replace(/-\d+$/, "") : ws.name;
      const group = groups.find(g => g.name === name && ws.id > 0);
      if (group) group.workspaces.push(ws);
      else groups.push({ name, workspaces: [ws] });
    }
    return groups;
  }

  spacing: 5

  component Well: Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + 2 * 9
    implicitHeight: 20
    radius: height / 2
    color: Theme.overlay(0.07)

    Row {
      id: row

      anchors.centerIn: parent
      spacing: 6
    }
  }

  component Dot: Item {
    id: dot

    property HyprlandWorkspace workspace: null
    property int number: 0
    readonly property bool shown: workspace !== null && root.monitor?.activeWorkspace === workspace
    readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
    readonly property bool urgent: workspace?.urgent ?? false
    readonly property color ink: urgent ? Theme.destructive : shown ? Theme.fg : Theme.overlay(area.containsMouse ? 0.95 : occupied ? 0.65 : 0.25)

    anchors.verticalCenter: parent?.verticalCenter
    width: shown ? 20 : 7
    height: 7

    Behavior on width {
      NumberAnimation {
        duration: 250
        easing.type: Easing.OutCubic
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      // An unfocused monitor's shown workspace is a dimmer pill.
      opacity: dot.shown && !root.focused ? 0.5 : 1
      color: dot.ink
      scale: area.pressed ? 0.85 : area.containsMouse && !dot.shown ? 1.25 : 1

      Behavior on color {
        ColorAnimation {
          duration: 150
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutQuad
        }
      }
    }

    MouseArea {
      id: area

      anchors.centerIn: parent
      width: parent.width + 6
      height: 20
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      // On press, which feels quicker than a click.
      onPressed: {
        Panels.close();
        const target = dot.number > 0 ? String(dot.number) : `name:${dot.workspace?.name}`;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(target)} })`);
      }
    }
  }

  Well {
    Repeater {
      model: root.own

      Dot {
        required property int modelData

        number: modelData
        workspace: Hyprland.workspaces.values.find(ws => ws.id === modelData) ?? null
      }
    }

  }

  Repeater {
    model: root.groups

    Well {
      id: chip

      required property var modelData

      spacing: 5

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: chip.modelData.name
        color: Theme.fgDim
        font: Qt.font({ family: Theme.body.family, pointSize: 8, weight: Font.Bold })
      }

      Repeater {
        model: chip.modelData.workspaces

        Dot {
          required property HyprlandWorkspace modelData

          workspace: modelData
          number: modelData?.id ?? 0
        }
      }
    }
  }
}
