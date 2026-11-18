import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

PanelWindow {
  id: root

  // Hyprland.monitorFor() is not reactive: it stays null if the output appears before the monitor.
  readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
  readonly property int inset: 8

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 34
  color: "transparent"

  WlrLayershell.namespace: "quickshell:bar"

  ConvexShape {
    anchors.fill: parent
    leftWidth: leftTab.width + 2 * root.inset + flare
    centerX: centerTab.x - flare - 4
    centerWidth: centerTab.width + 2 * flare + 8
    rightWidth: rightTab.width > 0 ? rightTab.width + 2 * root.inset + flare : 0
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: Panels.close()
  }

  Row {
    id: leftTab

    x: root.inset
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    NixLogo {
      anchors.verticalCenter: parent.verticalCenter
    }

    Workspaces {
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
    }
  }

  Clock {
    id: centerTab

    anchors.centerIn: parent
  }

  Row {
    id: rightTab

    anchors {
      right: parent.right
      rightMargin: root.inset
      verticalCenter: parent.verticalCenter
    }

    Battery {
      anchors.verticalCenter: parent.verticalCenter
    }

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }
  }
}
