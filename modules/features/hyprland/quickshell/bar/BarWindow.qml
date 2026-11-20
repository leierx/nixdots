import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

PanelWindow {
  id: root

  // Taken once: the screen object dangles while its monitor goes.
  property string screenName: ""
  // Hyprland.monitorFor() is not reactive: it stays null if the output appears before the monitor.
  readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screenName) ?? null
  readonly property int inset: 8

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 34
  color: Theme.panel
  Component.onCompleted: screenName = screen?.name ?? ""

  WlrLayershell.namespace: "quickshell:bar"

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: Panels.close()
  }

  Row {
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
    spacing: 2

    Row {
      id: status

      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      PrivacyIndicator {
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

      Cup {
        anchors.verticalCenter: parent.verticalCenter
      }

      Bell {
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
      // What the right side has left before it would reach the clock.
      room: (root.width - clock.width) / 2 - Theme.gap - root.inset - status.width - 2
    }
  }
}
