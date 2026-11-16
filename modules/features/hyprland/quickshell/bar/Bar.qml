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

  // Quickshell keeps Hyprland's state by its events, but misses some: it only
  // refreshes monitors as one comes or goes and ignores renames, leaving
  // workspaces on stale monitors and with stale names, and it reads windows'
  // floating and group state, which the bar turns solid by, only on request.
  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      if (["monitoraddedv2", "monitorremovedv2", "changeworkspaceid", "renameworkspace"].includes(event.name)) {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
      } else if (["openwindow", "movewindowv2", "changefloatingmode", "togglegroup", "moveintogroup", "moveoutofgroup"].includes(event.name)) {
        Hyprland.refreshToplevels();
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
