pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.nix

// hyprsplit gives monitor k the workspaces k*n+1 … (k+1)*n.
Singleton {
  id: root

  readonly property int perMonitor: Hyprsplit.workspaces

  function index(workspaceId: int): int {
    return (workspaceId - 1) % perMonitor + 1;
  }

  // "DP2-1" for the first workspace of DP-2; the bare id while the owner is unknown.
  function foreignLabel(workspaceId: int): string {
    const owner = Math.floor((workspaceId - 1) / perMonitor);
    const name = Hyprland.monitors.values.find(m => m.id === owner)?.name ?? state.names[owner];
    return name ? `${name.replace(/-/g, "")}-${index(workspaceId)}` : String(workspaceId);
  }

  // Kept per id, so a workspace that outlives its monitor still names it; Hyprland reuses ids, so the latest wins.
  readonly property var live: Hyprland.monitors.values.filter(m => m.id >= 0).map(m => [m.id, m.name])
  onLiveChanged: remember()
  // A change handler misses the monitors already there when this is first read.
  Component.onCompleted: remember()

  function remember(): void {
    const names = Object.assign({}, state.names);
    for (const [id, name] of live) names[id] = name;
    if (JSON.stringify(names) !== JSON.stringify(state.names)) state.names = names;
  }

  StateFile {
    name: "monitors.json"
    // Read before the first monitor arrives, which would otherwise overwrite it.
    blockLoading: true

    JsonAdapter {
      id: state

      property var names: ({})
    }
  }
}
