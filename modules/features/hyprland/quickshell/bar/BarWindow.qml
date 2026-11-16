import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

PanelWindow {
  id: root

  // Hyprland.monitorFor() is not reactive: it stays null if the output appears before the monitor.
  readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 35
  color: Theme.panel

  WlrLayershell.namespace: "quickshell:bar"

  // A click on the bar besides its buttons closes the open panel.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: Panels.close()
  }

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
