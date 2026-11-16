pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
  id: root

  required property HyprlandMonitor monitor
  readonly property var own: {
    if (!monitor || monitor.id < 0) return [];
    const first = monitor.id * WorkspaceOwners.perMonitor + 1;
    return Array.from({ length: WorkspaceOwners.perMonitor }, (_, i) => String(first + i));
  }
  readonly property var foreign: !monitor ? [] : Hyprland.workspaces.values
    .filter(ws => ws.monitor === monitor && !ws.name.startsWith("special:") && !own.includes(ws.address))
    .sort((a, b) => (b.id > 0) - (a.id > 0) || a.id - b.id || a.name.localeCompare(b.name))
    .map(ws => ws.address)

  spacing: 0

  Repeater {
    model: ScriptModel {
      values: root.own.concat(root.foreign)
    }

    WorkspaceButton {
      required property string modelData

      address: modelData
      monitor: root.monitor
      foreign: !root.own.includes(modelData)
    }
  }
}
