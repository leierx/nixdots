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
  // Shell's panel buttons sit in their 3 px transparent border.
  readonly property int inset: (Theme.barHeight - Theme.barItemHeight) / 2

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Theme.barHeight
  color: Theme.panelBg
  Component.onCompleted: screenName = screen?.name ?? ""

  WlrLayershell.namespace: "quickshell:bar"

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.ArrowCursor
    acceptedButtons: Qt.AllButtons
    onPressed: Panels.close()
  }

  Workspaces {
    x: Theme.padding
    height: root.height
    anchors.verticalCenter: parent.verticalCenter
    monitor: root.monitor
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
    spacing: 0

    StatusButton {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }
  }
}
