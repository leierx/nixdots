import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

Scope {
  IpcHandler {
    target: "bar"

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
      if (!["monitoraddedv2", "monitorremovedv2", "changeworkspaceid", "renameworkspace"].includes(event.name)) return;
      Hyprland.refreshMonitors();
      Hyprland.refreshWorkspaces();
      settled.restart();
    }
  }

  // Quickshell drops a refresh while one is under way, so a burst of hotplugs gets one more once it settles.
  Timer {
    id: settled

    interval: 300
    onTriggered: {
      Hyprland.refreshMonitors();
      Hyprland.refreshWorkspaces();
    }
  }

  Variants {
    model: Screens.real

    BarWindow {
      required property ShellScreen modelData

      screen: modelData
    }
  }
}
