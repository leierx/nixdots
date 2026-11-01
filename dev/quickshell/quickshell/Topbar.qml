import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick

PanelWindow {
  id: root
  required property var modelData
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 42

  readonly property color fg: "#f1f1f1"
  readonly property color blue: "#0E66D0"
  readonly property color yellow: "#F1C50F"
  readonly property color red: "#F13A31"
  readonly property color activeBg: "#40ffffff"
  readonly property color hoverBg: "#26ffffff"
  readonly property int fontSize: 16

  // hyprsplit gives every monitor its own index-numbered workspace block,
  // so each bar shows only the workspaces bound to its monitor, numbered 1..N.
  readonly property string myMonitorName: {
    const m = Hyprland.monitorFor(modelData)
    return m ? m.name : ""
  }
  property var myWorkspaces: []

  function refreshWorkspaces() {
    const vals = Hyprland.workspaces.values
    const mine = []
    for (let i = 0; i < vals.length; i++) {
      if (vals[i].monitor && vals[i].monitor.name === root.myMonitorName) mine.push(vals[i])
    }
    mine.sort((a, b) => a.id - b.id)
    const wrapped = []
    for (let i = 0; i < mine.length; i++) {
      wrapped.push({ ws: mine[i], label: i + 1 })
    }
    root.myWorkspaces = wrapped
  }

  Component.onCompleted: root.refreshWorkspaces()

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.refreshWorkspaces() }
  }

  Rectangle {
    id: barBg
    anchors.fill: parent
    color: "#000"
  }

  Row {
    anchors {
      left: parent.left
      leftMargin: 2
      verticalCenter: parent.verticalCenter
    }

    Item {
      width: 38
      height: 20
      Image {
        anchors.centerIn: parent
        source: "assets/nixos.svg"
        sourceSize.width: 20
        sourceSize.height: 20
      }
    }

    Repeater {
      model: root.myWorkspaces

      Rectangle {
        id: wsButton
        required property var modelData
        property bool hovered: false

        width: 32
        height: 26
        radius: 3
        color: hovered ? root.hoverBg : (modelData.ws.active ? root.activeBg : "transparent")

        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: root.fg
          font {
            family: "Adwaita Sans"
            pixelSize: root.fontSize
            bold: true
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: wsButton.hovered = true
          onExited: wsButton.hovered = false
          onClicked: modelData.ws.activate()
        }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, "ddd dd MMMM '‧' HH:mm")
    color: root.fg
    font {
      family: "Adwaita Sans"
      pixelSize: root.fontSize
      weight: Font.Medium
    }

    SystemClock { id: clock }
  }

  Row {
    anchors {
      right: parent.right
      rightMargin: 2
      verticalCenter: parent.verticalCenter
    }
    spacing: 6

    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: batteryText.width + 20
      height: 26

      Text {
        id: batteryText
        anchors.centerIn: parent
        property var bat: UPower.displayDevice
        text: bat.ready && bat.isLaptopBattery ? Math.round(bat.percentage) + "%" : ""
        color: bat.state === UPowerDeviceState.Charging
          ? root.blue
          : bat.percentage <= 10 ? root.red
          : bat.percentage <= 25 ? root.yellow
          : root.fg
        font {
          family: "Adwaita Sans"
          pixelSize: root.fontSize
          weight: Font.Medium
        }
      }
    }

    Repeater {
      model: SystemTray.items

      Rectangle {
        id: trayIcon
        required property var modelData
        property bool hovered: false

        width: 26
        height: 24
        radius: 5
        color: hovered ? root.hoverBg : "transparent"

        IconImage {
          anchors.centerIn: parent
          width: 20
          height: 20
          source: modelData.icon
        }

        MouseArea {
          id: trayMouseArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onEntered: trayIcon.hovered = true
          onExited: trayIcon.hovered = false
onClicked: (mouse) => {
              if (mouse.button === Qt.RightButton && modelData.menu) {
                const pos = trayMouseArea.mapToItem(barBg, mouse.x, mouse.y)
                modelData.display(root, pos.x, pos.y)
              } else if (mouse.button === Qt.LeftButton) {
                modelData.activate()
}
          }
        }
      }
    }
  }
}