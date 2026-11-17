pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.notifications

Item {
  id: root

  required property NotifEntry entry
  property bool expanded: false
  property bool single: false
  property bool dimmed: false

  readonly property bool boxed: expanded && !single
  readonly property bool truncated: line.truncated

  implicitHeight: box.height

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: box
    // Collapsed, or alone, the group takes every click.
    enabled: root.boxed
    onSwiped: left => swipe.slideAway(left, root.entry.dismissal())
    onTapped: button => {
      if (button !== Qt.LeftButton) {
        swipe.slideAway(false, root.entry.dismissal());
      } else if (root.entry.defaultAction) {
        root.entry.defaultAction.invoke();
        Panels.close();
      }
    }
  }

  Rectangle {
    id: box

    width: root.width
    height: content.implicitHeight + (root.boxed ? Theme.padding * 2 : 0)
    radius: Theme.buttonRadius
    color: !root.boxed ? "transparent" : hover.hovered ? Theme.cardHover : Theme.card
    border.width: root.boxed && root.entry.critical ? 1 : 0
    border.color: Theme.destructive
    opacity: root.dimmed ? 0.55 : 1
    clip: true

    Behavior on height {
      NumberAnimation {
        duration: 200
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 200
      }
    }

    HoverHandler {
      id: hover

      enabled: root.boxed
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.boxed ? Theme.padding : 0
      }
      spacing: 8

      RowLayout {
        visible: !root.expanded && !(root.single && root.entry.body === "")
        Layout.fillWidth: true
        spacing: 8

        Text {
          visible: !root.single
          Layout.maximumWidth: content.width * 0.6
          text: root.entry.notification.summary
          textFormat: Text.PlainText
          color: Theme.fg
          elide: Text.ElideRight
          font: Theme.heading
        }

        NotificationText {
          id: line

          Layout.fillWidth: true
          text: root.entry.body.replace(/\n/g, " ")
          // Eliding StyledText takes wrapping to one line.
          maximumLineCount: 1
          onLinkOpened: Panels.close()
        }

        NotificationAge {
          visible: !root.single
          entry: root.entry
        }
      }

      RowLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          // A lone notification's image is the group's icon.
          visible: !root.single && source != ""
          Layout.alignment: Qt.AlignVCenter
          source: root.single ? "" : root.entry.notification.image
          radius: Theme.buttonRadius
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          RowLayout {
            visible: !root.single
            Layout.fillWidth: true
            spacing: 8

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

            NotificationAge {
              Layout.alignment: Qt.AlignTop
              entry: root.entry
            }

            CloseButton {
              Layout.alignment: Qt.AlignTop
              opacity: hover.hovered ? 1 : 0
              enabled: hover.hovered
              onClicked: swipe.slideAway(false, root.entry.dismissal())
            }
          }

          NotificationText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            onLinkOpened: Panels.close()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: root.expanded && root.entry.progress !== undefined
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
        visible: root.expanded && actions.length > 0
        actions: root.entry.buttons
      }
    }
  }
}
