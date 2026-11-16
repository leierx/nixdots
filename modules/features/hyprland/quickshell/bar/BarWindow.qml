import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

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
  implicitHeight: 34
  color: Theme.bg

  WlrLayershell.namespace: "quickshell:bar"

  Row {
    anchors {
      left: parent.left
      verticalCenter: parent.verticalCenter
    }
    spacing: 4

    NixLogo {
      implicitHeight: root.implicitHeight
    }

    Workspaces {
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
    }
  }

  Clock {
    anchors.centerIn: parent
  }

  Row {
    anchors {
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    spacing: 4

    Battery {
      anchors.verticalCenter: parent.verticalCenter
    }

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
      size: root.implicitHeight
    }
  }
}
