pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.nix

// Which monitor owns a workspace. hyprsplit gives the monitor with id k the
// workspaces k*n+1 … (k+1)*n. A workspace that outlives its monitor, moved to
// another when it was unplugged or disabled, is named after the monitor it
// belongs to, so the connector last seen with each id is remembered, and saved
// for a restart while it is gone.
Singleton {
  id: root

  readonly property int perMonitor: Hyprsplit.workspaces

  function ownerId(workspaceId: int): int {
    return Math.floor((workspaceId - 1) / perMonitor);
  }

  // Its place among its monitor's workspaces, from 1.
  function index(workspaceId: int): int {
    return (workspaceId - 1) % perMonitor + 1;
  }

  // "DP2-1" for the first workspace of DP-2; the bare id while the owner is unknown.
  function foreignLabel(workspaceId: int): string {
    const owner = Hyprland.monitors.values.find(m => m.id === ownerId(workspaceId))?.name ?? state.names[ownerId(workspaceId)];
    return owner ? `${owner.replace(/-/g, "")}-${index(workspaceId)}` : String(workspaceId);
  }

  // Hyprland reuses an id for another connector once its own is gone, so the
  // latest one seen with it wins.
  readonly property var live: Hyprland.monitors.values.filter(m => m.id >= 0).map(m => [m.id, m.name])
  onLiveChanged: {
    const names = Object.assign({}, state.names);
    for (const [id, name] of live) names[id] = name;
    if (JSON.stringify(names) !== JSON.stringify(state.names)) state.names = names;
  }

  FileView {
    path: Quickshell.statePath("monitors.json")
    // Read before the first monitor arrives, which would otherwise overwrite it.
    blockLoading: true
    // Until a monitor is seen, there is no file, which is fine.
    printErrors: false
    onAdapterUpdated: Qt.callLater(writeAdapter)
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn(`Reading ${path} failed: ${FileViewError.toString(error)}`);
    }
    onSaveFailed: error => console.warn(`Writing ${path} failed: ${FileViewError.toString(error)}`)

    JsonAdapter {
      id: state

      // Monitor id to connector name.
      property var names: ({})
    }
  }
}
