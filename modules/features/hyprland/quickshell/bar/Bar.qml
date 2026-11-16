import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The bar along the top of every monitor. Scripts reach it with
// `qs ipc -c shell call bar <function>`.
Scope {
  IpcHandler {
    target: "bar"

    // A made-up battery, to see the indicator on a machine without one:
    // `fakeBattery 15 false` is 15 % on battery.
    function fakeBattery(percent: int, plugged: bool): void {
      Power.fake = { percent, plugged };
    }

    function realBattery(): void {
      Power.fake = null;
    }
  }

  // Quickshell keeps Hyprland's state by its events, but only refreshes
  // monitors as one comes or goes and ignores renames, leaving workspaces on
  // stale monitors and with stale names.
  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      if (["monitoraddedv2", "monitorremovedv2", "changeworkspaceid", "renameworkspace"].includes(event.name)) {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
      }
    }
  }

  Variants {
    model: Quickshell.screens

    BarWindow {
      required property ShellScreen modelData

      screen: modelData
    }
  }
}
