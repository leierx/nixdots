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
  color: Theme.panel

  WlrLayershell.namespace: "quickshell:bar"

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: Panels.close()
  }

  Row {
    id: start

    x: root.inset
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    NixLogo {
      anchors.verticalCenter: parent.verticalCenter
    }

    Workspaces {
      height: root.height
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
    }

    Item {
      width: 10
      height: 1
    }

    // Up to the clock, less a gap.
    WindowTitle {
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
      maxWidth: clock.x - start.x - x - 24
    }
  }

  Clock {
    id: clock

    anchors.centerIn: parent
  }

  Row {
    anchors {
      right: parent.right
      rightMargin: root.inset
      verticalCenter: parent.verticalCenter
    }
    spacing: 4

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }

    VolumeButton {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }

    Battery {
      anchors.verticalCenter: parent.verticalCenter
    }

    Bell {
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
