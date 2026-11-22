import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common
import qs.controls

Scope {
  // The control centre's shortcut lives in a singleton, made on first use; also recover windows opened before this attached.
  Component.onCompleted: {
    Controls.menu;
    windowsSettled.restart();
  }

  IpcHandler {
    target: "bar"

    // COUNT outputs, the one in use well down the list and some with hostile names, as no real sound server would have.
    function fakeOutputs(count: int): void {
      const names = Array.from({ length: count }, (_, i) => i === 3 ? "A sink with a name a kilobyte long ".repeat(30) : i === 5 ? "Right\u202eto left\nand two lines\u200b" : `Output ${i + 1}`);
      Volume.fake = { volume: 0.64, muted: false, current: Math.floor(count * 0.6), devices: names };
    }

    function realVolume(): void {
      Volume.fake = null;
    }
  }

  // Quickshell ignores renamed and moved workspaces.
  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      // Quickshell drops a window opened on a workspace it has not loaded yet, as at login, for good.
      if (event.name === "openwindow") {
        Hyprland.refreshToplevels();
        windowsSettled.restart();
        return;
      }
      if (["changeworkspaceid", "renameworkspace"].includes(event.name)) Hyprland.refreshWorkspaces();
    }
  }

  Timer {
    id: windowsSettled

    interval: 300
    onTriggered: {
      Hyprland.refreshWorkspaces();
      Hyprland.refreshToplevels();
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
