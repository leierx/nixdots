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

  // The bar's right end, which reveals the tray: the status button and the room the tray takes left of it, short of the clock; the buttons are its children, as hover reaches ancestors and not siblings beneath.
  Item {
    anchors.right: parent.right
    width: Math.max(0, Math.min(status.width + tray.most + Theme.basePadding + root.inset, root.width - clock.x - clock.width - Theme.padding))
    height: root.height

    HoverHandler {
      id: zone
    }

    Row {
      anchors {
        right: parent.right
        rightMargin: root.inset
        verticalCenter: parent.verticalCenter
      }
      spacing: 0

      Tray {
        id: tray

        anchors.verticalCenter: parent.verticalCenter
        screen: root.screen
        wanted: zone.hovered
      }

      StatusButton {
        id: status

        anchors.verticalCenter: parent.verticalCenter
        screen: root.screen
      }
    }
  }
}
