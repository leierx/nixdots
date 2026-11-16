import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.nix

// One monitor's bar: the NixOS logo and the monitor's workspaces on the left,
// the clock in the middle, the battery and the tray on the right.
PanelWindow {
  id: root

  // Looked up rather than Hyprland.monitorFor(), which is not a binding and
  // stays null when the output comes before Hyprland announces the monitor.
  readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 35
  // GNOME Shell's panel black.
  color: Colors.dark_5

  WlrLayershell.namespace: "quickshell:bar"

  Row {
    anchors {
      left: parent.left
      leftMargin: 2
      verticalCenter: parent.verticalCenter
    }

    NixLogo {}

    Workspaces {
      monitor: root.monitor
    }
  }

  Clock {
    anchors.centerIn: parent
  }

  Row {
    anchors {
      right: parent.right
      rightMargin: 2
      verticalCenter: parent.verticalCenter
    }

    Battery {
      anchors.verticalCenter: parent.verticalCenter
    }

    Tray {
      screen: root.screen
    }
  }
}
