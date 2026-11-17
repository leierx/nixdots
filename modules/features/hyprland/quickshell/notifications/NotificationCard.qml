pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

Item {
  id: root

  required property NotifEntry entry

  property bool expanded: false

  implicitHeight: card.height

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: card
    onSwiped: left => {
      if (!left) swipe.slideAway(false);
    }
    onGone: root.entry.notification.dismiss()
    onTapped: button => {
      if (button !== Qt.LeftButton) swipe.slideAway(false);
      else if (body.truncated) root.expanded = true;
      else if (root.entry.defaultAction) root.entry.defaultAction.invoke();
      else root.entry.popup = false;
    }
  }

  HoverHandler {
    id: hover

    onHoveredChanged: root.entry.hovered = hovered
  }

  Card {
    id: card

    // Popups only leave towards the screen's edge.
    x: Math.max(0, swipe.distance)
    width: root.width
    height: content.implicitHeight + 24
    border.color: root.entry.critical ? Theme.destructive : Theme.outline
    opacity: 1 - x / width

    Behavior on x {
      enabled: !swipe.dragging

      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: 12
      }
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        IconImage {
          visible: root.entry.appIcon !== ""
          source: root.entry.appIcon
          implicitSize: 16
        }

        Text {
          Layout.fillWidth: true
          text: root.entry.notification.appName || "Notification"
          color: Theme.fgDim
          elide: Text.ElideRight
          font: Theme.caption
        }

        Text {
          text: Notifs.age(root.entry.time)
          color: Theme.fgDim
          font: Theme.caption
        }

        Button {
          visible: body.truncated || root.expanded
          implicitWidth: 24
          implicitHeight: 24
          radius: height / 2
          flat: true
          expander: true
          open: root.expanded
          onClicked: root.expanded = !root.expanded
        }

        // Only under the pointer, as GNOME shows it.
        CloseButton {
          opacity: hover.hovered ? 1 : 0
          enabled: hover.hovered
          onClicked: swipe.slideAway(false)
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          visible: source != ""
          Layout.alignment: Qt.AlignVCenter
          source: root.entry.notification.image
          radius: Theme.buttonRadius
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            Layout.fillWidth: true
            text: root.entry.notification.summary
            textFormat: Text.PlainText
            color: Theme.fg
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font: Theme.heading
          }

          Text {
            id: body

            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            textFormat: Text.StyledText
            color: Theme.fg
            linkColor: Theme.accent
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 1000 : 4
            elide: Text.ElideRight
            font: Theme.body
            onLinkActivated: link => Notifs.openUrl(link)

            HoverHandler {
              cursorShape: body.hoveredLink ? Qt.PointingHandCursor : undefined
            }
          }

        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: root.entry.progress !== undefined
        implicitHeight: 8
        radius: height / 2
        color: Theme.trough

        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.entry.progress ?? 0)) / 100
          height: parent.height
          radius: parent.radius
          color: Theme.accentBg
        }
      }

      NotificationActions {
        Layout.fillWidth: true
        actions: root.entry.buttons
      }
    }
  }
}
