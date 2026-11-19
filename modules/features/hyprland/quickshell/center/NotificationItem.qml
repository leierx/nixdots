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
  // A lone notification's body has the lines its summary leaves; a group's rows have one each.
  property int lines: 2
  property bool closable: false

  signal closed()

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
      } else {
        swipe.slideAway(false, root.entry.dismissal());
      }
    }
  }

  Rectangle {
    id: box

    width: root.width
    height: content.implicitHeight + (root.boxed ? 16 : 0)
    radius: Theme.buttonRadius
    color: {
      if (!root.boxed) return "transparent";
      if (root.entry.critical) return hover.hovered ? Theme.criticalCardHover : Theme.criticalCard;
      return hover.hovered ? Theme.cardHover : Theme.card;
    }
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
        margins: root.boxed ? 8 : 0
      }
      spacing: 6

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
          // Eliding StyledText takes a line limit.
          maximumLineCount: root.single ? root.lines : 1
          onLinkOpened: Panels.close()
        }

        NotificationStamp {
          visible: !root.single
          entry: root.entry
          closable: root.closable
          onClosed: root.closed()
        }
      }

      RowLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          // A lone notification's image is the group's icon.
          visible: !root.single && root.entry.notification.image !== ""
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
        onInvoked: action => root.entry.invoke(action)
      }
    }
  }
}
