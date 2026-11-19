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
  property real remaining: 1

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
      else if (root.entry.buttons.length === 1) root.entry.invoke(root.entry.buttons[0]);
      else root.entry.popup = false;
    }
  }

  HoverHandler {
    onHoveredChanged: root.entry.hovered = hovered
  }

  // A card gone under the pointer, its monitor unplugged say, never reports the pointer leaving.
  Component.onDestruction: if (root.entry) root.entry.hovered = false

  // Follows the timeout's own timer: frozen while it is held, from full each time it starts again.
  NumberAnimation {
    id: countdown

    target: root
    property: "remaining"
    from: 1
    to: 0
    duration: root.entry.timeout
    running: root.entry.timer.running
  }

  Connections {
    target: root.entry

    function onTimeoutRestarted() {
      countdown.restart();
    }
  }

  FontMetrics {
    id: line

    font: Theme.heading
  }

  Card {
    id: card

    width: root.width
    height: content.implicitHeight + 2 * Theme.padding
    border.color: root.entry.critical ? Theme.destructive : Theme.outline
    opacity: 1 - x / width

    ClippingRectangle {
      anchors.fill: parent
      radius: card.radius
      color: "transparent"
      visible: root.entry.timeout > 0

      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width * root.remaining
        height: 3
        color: Theme.accentBg
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
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          visible: root.entry.notification.image !== ""
          Layout.alignment: Qt.AlignVCenter
          source: root.entry.notification.image
          radius: Theme.buttonRadius
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          spacing: 2

          RowLayout {
            Layout.fillWidth: true
            visible: summary.text !== "" || root.expandable
            spacing: 6

            Text {
              id: summary

              Layout.fillWidth: true
              Layout.alignment: Qt.AlignTop
              text: root.entry.notification.summary
              textFormat: Text.PlainText
              color: Theme.fg
              wrapMode: Text.Wrap
              maximumLineCount: root.expanded ? 6 : 2
              elide: Text.ElideRight
              font: Theme.heading
            }

            // Overhanging the line, so the arrow costs it no height.
            Item {
              Layout.alignment: Qt.AlignTop
              visible: root.expandable
              implicitWidth: 24
              implicitHeight: line.height

              ExpandButton {
                anchors.centerIn: parent
                open: root.expanded
                onClicked: root.expanded = !root.expanded
              }
            }
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
