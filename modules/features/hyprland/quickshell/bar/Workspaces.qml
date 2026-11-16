pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

// The monitor's workspaces: always its own n, then any it holds from another
// monitor, named after that one ("DP2-1"), and named workspaces by name.
// Special workspaces stay out. Buttons are keyed by workspace address, so
// they keep their place as workspaces come and go.
Row {
  id: root

  required property HyprlandMonitor monitor
  readonly property var own: {
    if (!monitor || monitor.id < 0) return [];
    const first = monitor.id * WorkspaceOwners.perMonitor + 1;
    return Array.from({ length: WorkspaceOwners.perMonitor }, (_, i) => String(first + i));
  }
  readonly property var foreign: Hyprland.workspaces.values
    .filter(ws => ws.monitor === monitor && !ws.name.startsWith("special:") && !own.includes(ws.address))
    // Numbered by id, then named by name.
    .sort((a, b) => (b.id > 0) - (a.id > 0) || a.id - b.id || a.name.localeCompare(b.name))
    .map(ws => ws.address)

  spacing: 4

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
