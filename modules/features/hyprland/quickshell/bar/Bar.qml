import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common
import qs.controls

Scope {
  // The control centre's shortcut lives in a singleton, made on first use.
  Component.onCompleted: Controls.menu

  IpcHandler {
    target: "bar"

    function fakeBattery(percent: int, plugged: bool): void {
      Power.fake = { percent, plugged };
    }

    function fakeVolume(percent: int, muted: bool): void {
      Volume.fake = { volume: percent / 100, muted, current: 0, devices: ["Speakers", "Headphones", "HDMI / DisplayPort"] };
    }

    // COUNT outputs, the one in use well down the list and some with hostile names, as no real sound server would have.
    function fakeOutputs(count: int): void {
      const names = Array.from({ length: count }, (_, i) => i === 3 ? "A sink with a name a kilobyte long ".repeat(30) : i === 5 ? "Right\u202eto left\nand two lines\u200b" : `Output ${i + 1}`);
      Volume.fake = { volume: 0.64, muted: false, current: Math.floor(count * 0.6), devices: names };
    }

    function realVolume(): void {
      Volume.fake = null;
    }

    function realBattery(): void {
      Power.fake = null;
    }
  }

  // Quickshell refreshes monitors only as one is added, and ignores renamed workspaces.
  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      // Quickshell drops a window opened on a workspace it has not loaded yet, as at login, for good.
      if (event.name === "openwindow") {
        Hyprland.refreshToplevels();
        windowsSettled.restart();
        return;
      }
      if (!["monitoraddedv2", "monitorremovedv2", "changeworkspaceid", "renameworkspace"].includes(event.name)) return;
      Hyprland.refreshMonitors();
      Hyprland.refreshWorkspaces();
      settled.restart();
    }
  }

  // Quickshell drops a refresh while one is under way, so a burst gets one more once it settles.
  Timer {
    id: settled

    interval: 300
    onTriggered: {
      Hyprland.refreshMonitors();
      Hyprland.refreshWorkspaces();
    }
  }

  Timer {
    id: windowsSettled

    interval: 300
    onTriggered: Hyprland.refreshToplevels()
  }

  Variants {
    model: Screens.real

    BarWindow {
      required property ShellScreen modelData

      screen: modelData
    }
  }
}
