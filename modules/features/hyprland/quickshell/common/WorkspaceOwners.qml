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

  function owner(workspaceId: int): int {
    return Math.floor((workspaceId - 1) / perMonitor);
  }

  // As the bar of the monitor it is on names it: its own by number, another's by its owner, a named one by name.
  function label(workspace: HyprlandWorkspace, monitor: HyprlandMonitor): string {
    if (workspace.id <= 0) return workspace.name.replace(/^special:/, "");
    return owner(workspace.id) === monitor?.id ? String(index(workspace.id)) : foreignLabel(workspace.id);
  }

  // "DP2-1" for the first workspace of DP-2; the bare id while the owner is unknown.
  function foreignLabel(workspaceId: int): string {
    const owner = root.owner(workspaceId);
    const name = live.find(([id]) => id === owner)?.[1] ?? state.names?.[owner];
    return typeof name === "string" && name ? `${name.replace(/-/g, "")}-${index(workspaceId)}` : String(workspaceId);
  }

  // Kept per id, so a workspace that outlives its monitor still names it; Hyprland reuses ids, so the latest wins, but never for its FALLBACK.
  readonly property var live: Hyprland.monitors.values.filter(m => m.id >= 0 && m.name !== Screens.fallback).map(m => [m.id, m.name])
  onLiveChanged: remember()
  // A change handler misses the monitors already there when this is first read.
  Component.onCompleted: remember()

  // The saved names are read before any are written: the read is async even with blockLoading, as an adapter has it.
  property bool loaded: false

  function remember(): void {
    if (!root.loaded) return;
    const names = Object.assign({}, typeof state.names === "object" && !Array.isArray(state.names) ? state.names : {});
    for (const [id, name] of live) names[id] = name;
    for (const id of Object.keys(names).filter(id => names[id] === Screens.fallback)) delete names[id];
    if (JSON.stringify(names) !== JSON.stringify(state.names)) state.names = names;
  }

  StateFile {
    id: file

    name: "monitors.json"
    onLoaded: {
      root.loaded = true;
      root.remember();
    }

    JsonAdapter {
      id: state

      property var names: ({})
    }
  }

  // No file yet: nothing to keep.
  Connections {
    target: file

    function onLoadFailed(): void {
      root.loaded = true;
      root.remember();
    }
  }
}
