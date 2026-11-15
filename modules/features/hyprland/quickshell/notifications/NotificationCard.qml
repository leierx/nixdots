pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common

// One popup: its app and age, then the image, summary and body, a progress bar
// if the app sends one, and the actions. A click runs the default action, or
// just puts the popup away; a right click or a swipe dismisses it.
Item {
  id: root

  required property NotifEntry entry

  readonly property Notification notification: entry?.notification ?? null
  readonly property NotificationAction defaultAction: notification?.actions.find(a => a.identifier === "default") ?? null
  readonly property var progress: notification?.hints.value
  readonly property string appIcon: Notifs.appIcon(notification)
  readonly property int imageSize: Theme.px(40)

  property bool expanded: false

  implicitHeight: card.implicitHeight

  function activate() {
    if (defaultAction) defaultAction.invoke();
    else entry.popup = false;
  }

  Rectangle {
    id: card

    width: root.width
    implicitHeight: content.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: root.entry?.critical ? Theme.urgent : Theme.border
    opacity: 1 - Math.abs(x) / width

    Behavior on x {
      enabled: !swipe.drag.active

      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    HoverHandler {
      id: hover

      onHoveredChanged: {
        root.entry.hovered = hovered;
      }
    }

    // Under the buttons and links, so they get their clicks first.
    MouseArea {
      id: swipe

      property bool swiped: false

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      drag {
        target: card
        axis: Drag.XAxis
        // Popups only leave towards the screen edge.
        minimumX: 0
        maximumX: card.width
      }
      onPressed: swiped = false
      onPositionChanged: {
        if (drag.active) swiped = true;
      }
      onReleased: {
        if (!swiped) return;
        if (Math.abs(card.x) > card.width / 3) root.notification.dismiss();
        else card.x = 0;
      }
      onClicked: mouse => {
        if (swiped) return;
        if (mouse.button === Qt.RightButton) root.notification.dismiss();
        else root.activate();
      }
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
      }
      spacing: Theme.px(8)

      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(8)

        IconImage {
          visible: root.appIcon !== ""
          source: root.appIcon
          implicitSize: Theme.px(16)
        }

        Text {
          Layout.fillWidth: true
          text: root.notification?.appName || "Notification"
          color: Theme.fgDim
          elide: Text.ElideRight
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSmall
          }
        }

        Text {
          text: Notifs.age(root.entry?.time ?? Notifs.now)
          color: Theme.fgDim
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSmall
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(12)

        ClippingRectangle {
          visible: !!root.notification?.image
          Layout.alignment: Qt.AlignTop
          implicitWidth: root.imageSize
          implicitHeight: root.imageSize
          radius: Theme.px(8)
          color: "transparent"

          Image {
            anchors.fill: parent
            source: root.notification?.image ?? ""
            sourceSize {
              width: root.imageSize * 2
              height: root.imageSize * 2
            }
            fillMode: Image.PreserveAspectCrop
            // The image provider reuses URLs for different notifications.
            cache: false
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Theme.px(2)

          Text {
            Layout.fillWidth: true
            text: root.notification?.summary ?? ""
            textFormat: Text.PlainText
            color: Theme.fg
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontTitle
              weight: Font.DemiBold
            }
          }

          Text {
            id: body

            Layout.fillWidth: true
            visible: text !== ""
            text: root.notification?.body ?? ""
            textFormat: Text.StyledText
            color: Theme.fgSoft
            linkColor: Theme.accent
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 1000 : 4
            elide: Text.ElideRight
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontBody
            }
            onLinkActivated: link => Notifs.openUrl(link)

            HoverHandler {
              cursorShape: body.hoveredLink ? Qt.PointingHandCursor : undefined
            }
          }

          Text {
            visible: body.truncated || root.expanded
            text: root.expanded ? "Show less" : "Show more"
            color: Theme.accent
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontSmall
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.expanded = !root.expanded
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: root.progress !== undefined
        implicitHeight: Theme.px(6)
        radius: height / 2
        color: Theme.selected

        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.progress ?? 0)) / 100
          height: parent.height
          radius: parent.radius
          color: Theme.accent
        }
      }

      NotificationActions {
        Layout.fillWidth: true
        actions: root.notification?.actions.filter(a => a.identifier !== "default") ?? []
      }
    }
  }
}
