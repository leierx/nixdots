pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

Item {
  id: root

  required property NotifEntry entry

  property bool expanded: false
  readonly property bool expandable: expanded || summary.truncated || body.truncated

  implicitHeight: card.height

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: card
    rightOnly: true
    onSwiped: left => {
      if (!left) swipe.slideAway(false, root.entry.dismissal());
    }
    onTapped: button => {
      if (button !== Qt.LeftButton) swipe.slideAway(false, root.entry.dismissal());
      else if (root.expandable) root.expanded = !root.expanded;
      else if (root.entry.defaultAction) root.entry.invoke(root.entry.defaultAction);
      else root.entry.popup = false;
    }
  }

  HoverHandler {
    onHoveredChanged: root.entry.hovered = hovered
  }

  // A card gone under the pointer, its monitor unplugged say, never reports the pointer leaving.
  Component.onDestruction: if (root.entry) root.entry.hovered = false

  Card {
    id: card

    width: root.width
    height: content.implicitHeight + 2 * Theme.padding
    border.color: root.entry.critical ? Theme.destructive : Theme.outline
    opacity: 1 - x / width

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
      }
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        Layout.minimumHeight: 24
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

        NotificationAge {
          entry: root.entry
        }

        ExpandButton {
          visible: root.expandable
          open: root.expanded
          onClicked: root.expanded = !root.expanded
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
            id: summary

            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.notification.summary
            textFormat: Text.PlainText
            color: Theme.fg
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 6 : 2
            elide: Text.ElideRight
            font: Theme.heading
          }

          // Expanded, still short enough that a popup always fits on the screen.
          NotificationText {
            id: body

            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            maximumLineCount: root.expanded ? 15 : 4
            onLinkOpened: root.entry.popup = false
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
        onInvoked: action => root.entry.invoke(action)
      }
    }
  }
}
