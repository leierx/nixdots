pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
      else if (root.expandable && !root.expanded) root.expanded = true;
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

    // Over a dark terminal the card alone blends in.
    Rectangle {
      id: stripe

      x: 8
      y: Theme.padding
      width: 3
      height: parent.height - 2 * Theme.padding
      radius: width / 2
      color: root.entry.critical ? Theme.destructive : Theme.accentBg
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: stripe.right
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
