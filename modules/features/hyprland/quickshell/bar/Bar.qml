import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.controls

Scope {
  // The control centre's shortcut lives in a singleton, made on first use; also recover windows opened before this attached.
  Component.onCompleted: {
    Controls.menu;
    windowsSettled.restart();
  }

  // Quickshell looks a renamed workspace up by the address the event does not carry (it sends the id), so misses it.
  Connections {
    target: Hyprland

    function onRawEvent(event: HyprlandEvent): void {
      // Quickshell drops a window opened on a workspace it has not loaded yet, as at login, for good.
      if (event.name === "openwindow") {
        Hyprland.refreshToplevels();
        windowsSettled.restart();
        return;
      }
      if (event.name === "renameworkspace") Hyprland.refreshWorkspaces();
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
