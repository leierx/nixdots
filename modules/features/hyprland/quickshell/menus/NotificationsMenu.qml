pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.notifications
import qs.services

// The notification center: every notification not yet dismissed, newest
// first, under a do-not-disturb switch and a button that clears them all.
// Up and Down select a notification, Enter runs its default action and Delete
// dismisses it. Opening it puts away the popups.
MenuWindow {
  id: root

  // The tallest the content has been since it opened, so dismissing
  // notifications leaves the card's top where it is.
  property real peakHeight: 0

  fullHeight: peakHeight
  cardWidth: Theme.notificationWidth + Theme.cardPadding * 2

  Component.onCompleted: Notifs.hidePopups()

  component Pill: Rectangle {
    id: pill

    property alias text: label.text
    property bool active: false

    signal clicked()

    implicitWidth: label.implicitWidth + Theme.px(28)
    implicitHeight: Theme.px(34)
    radius: height / 2
    color: active ? Theme.accent : area.containsMouse ? Theme.selected : Theme.raised

    Text {
      id: label

      anchors.centerIn: parent
      color: Theme.fg
      font {
        family: Theme.fontFamily
        pixelSize: Theme.smallSize
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }

  ColumnLayout {
    id: content

    width: parent.width
    spacing: Theme.px(12)
    onImplicitHeightChanged: root.peakHeight = Math.max(root.peakHeight, implicitHeight)

    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: Theme.px(4)
      spacing: Theme.px(8)

      Text {
        Layout.fillWidth: true
        text: "Notifications"
        color: Theme.fg
        font {
          family: Theme.fontFamily
          pixelSize: Theme.summarySize
          weight: Font.DemiBold
        }
      }

      Pill {
        text: "Do not disturb"
        active: Notifs.dnd
        onClicked: Notifs.dnd = !Notifs.dnd
      }

      Pill {
        text: "Clear all"
        visible: list.count > 0
        onClicked: Notifs.clear()
      }
    }

    ListView {
      id: list

      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(contentHeight, Theme.px(720))
      visible: count > 0
      spacing: Theme.px(8)
      clip: true
      focus: true
      boundsBehavior: Flickable.StopAtBounds
      model: ScriptModel {
        values: Notifs.entries
      }

      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
      Keys.onReturnPressed: currentItem?.activate()
      Keys.onEnterPressed: currentItem?.activate()
      Keys.onDeletePressed: currentItem?.notification.dismiss()

      delegate: NotificationCard {
        required property NotifEntry modelData

        width: ListView.view.width
        entry: modelData
        flat: true
        selected: ListView.isCurrentItem
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.topMargin: Theme.px(24)
      Layout.bottomMargin: Theme.px(24)
      visible: list.count === 0
      text: "No notifications"
      horizontalAlignment: Text.AlignHCenter
      color: Theme.fgDim
      font {
        family: Theme.fontFamily
        pixelSize: Theme.subtitleSize
      }
    }
  }
}
