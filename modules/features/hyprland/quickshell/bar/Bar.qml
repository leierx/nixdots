import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  IpcHandler {
    target: "bar"

    // `fakeBattery 15 false`: 15 % on battery, to see the indicator on a machine without one.
    function fakeBattery(percent: int, plugged: bool): void {
      Power.fake = { percent, plugged };
    }

    function realBattery(): void {
      Power.fake = null;
    }
  }

  // Quickshell refreshes monitors only as one is added, and ignores renamed workspaces.
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
