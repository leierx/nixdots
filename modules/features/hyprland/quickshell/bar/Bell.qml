import QtQuick
import qs.common
import qs.notifications

// The notification center's button: how many it holds, struck through while Do Not Disturb is on.
Item {
  id: root

  // Material Symbols' notifications and notifications_off
  readonly property string bell: "M200-200q-17 0-28.5-11.5T160-240q0-17 11.5-28.5T200-280h40v-280q0-83 50-147.5T420-792v-28q0-25 17.5-42.5T480-880q25 0 42.5 17.5T540-820v28q80 20 130 84.5T720-560v280h40q17 0 28.5 11.5T800-240q0 17-11.5 28.5T760-200H200Zm280-300Zm0 420q-33 0-56.5-23.5T400-160h160q0 33-23.5 56.5T480-80ZM320-280h320v-280q0-66-47-113t-113-47q-66 0-113 47t-47 113v280Z"
  readonly property string off: "M646-200H200q-17 0-28.5-11.5T160-240q0-17 11.5-28.5T200-280h40v-280q0-33 8.5-65t25.5-61l60 60q-7 16-10.5 32.5T320-560v280h248L84-764q-11-11-11-28t11-28q11-11 28-11t28 11l680 680q11 11 11.5 27.5T820-84q-11 11-28 11t-28-11L646-200ZM540-792q80 20 130 84.5T720-560v110q0 20-12.5 30T680-410q-15 0-27.5-10.5T640-451v-109q0-66-47-113t-113-47q-16 0-34 4t-32 10q-17 7-33.5 3T355-722q-8-13-5.5-27.5T365-771q13-7 27-12t28-9v-28q0-25 17.5-42.5T480-880q25 0 42.5 17.5T540-820v28Zm-96 388Zm36 324q-30 0-53.5-16.5T403-141q0-8 6.5-13.5T424-160h112q8 0 14.5 5.5T557-141q0 28-23.5 44.5T480-80Zm33-481Z"
  readonly property int count: Notifs.entries.length

  implicitWidth: 30
  implicitHeight: 26

  Rectangle {
    anchors.fill: parent
    radius: Theme.smallRadius
    color: Panels.active === "center" ? Theme.buttonChecked : area.containsMouse ? Theme.buttonHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }
  }

  Glyph {
    anchors.centerIn: parent
    path: Notifs.dnd ? root.off : root.bell
    size: 18
    color: Notifs.dnd ? Theme.fgDim : Theme.fg
  }

  Rectangle {
    x: parent.width / 2 + 1
    y: 1
    visible: root.count > 0 && !Notifs.dnd
    width: Math.max(13, number.implicitWidth + 6)
    height: 13
    radius: height / 2
    color: Theme.destructiveBg
    border.width: 1.5
    border.color: Theme.panel

    Text {
      id: number

      anchors.centerIn: parent
      text: root.count > 9 ? "9+" : root.count
      color: "white"
      font: Qt.font({ family: Theme.body.family, pointSize: 6, weight: Font.Bold })
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Panels.toggle("center")
  }
}
