pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.notifications

// One notification inside a group. Collapsed, a line of its summary and body;
// expanded, a card of its own with the image, the whole body and the actions.
// A click on the card runs its default action, or dismisses it if it has none
// and no buttons to choose from; a right or middle click or a swipe dismisses
// it. A group's only notification has its summary in the group's header and
// goes without a card.
Item {
  id: root

  required property NotifEntry entry
  property bool expanded: false
  property bool single: false
  property bool dimmed: false
  // How far a swipe in the group moves it.
  property real lean: 0

  signal swipeMoved(real distance)
  signal swipeEnded()

  readonly property bool boxed: expanded && !single
  readonly property int pad: 12

  implicitHeight: box.height

  function slideAway(left) {
    box.x = box.x;
    away.to = (left ? -1 : 1) * (width + 20);
    away.start();
  }

  NumberAnimation {
    id: away

    target: box
    property: "x"
    duration: 200
    easing.type: Easing.InCubic
    onFinished: root.entry.notification.dismiss()
  }

  SwipeArea {
    id: swipe

    anchors.fill: parent
    // Collapsed, the group takes every click.
    enabled: root.expanded
    onDistanceChanged: {
      if (dragging) root.swipeMoved(distance);
    }
    onDraggingChanged: {
      if (!dragging) root.swipeEnded();
    }
    onSwiped: left => root.slideAway(left)
    onTapped: button => {
      if (button !== Qt.LeftButton || root.entry.clickDismisses) {
        root.slideAway(false);
      } else if (root.entry.defaultAction) {
        root.entry.defaultAction.invoke();
        Panels.close();
      }
    }
  }

  Rectangle {
    id: box

    x: root.lean
    width: root.width
    height: content.implicitHeight + (root.boxed ? root.pad * 2 : 0)
    radius: Theme.buttonRadius
    color: !root.boxed ? "transparent" : hover.hovered ? Theme.cardHover : Theme.card
    border.width: root.boxed && root.entry.critical ? 1 : 0
    border.color: Theme.destructive
    opacity: root.dimmed ? 0.55 : 1
    clip: true

    Behavior on x {
      enabled: !swipe.dragging

      NumberAnimation {
        duration: 250
        easing.type: Easing.OutCubic
      }
    }

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

      enabled: root.expanded
      cursorShape: root.entry.defaultAction || root.entry.clickDismisses ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.boxed ? root.pad : 0
      }
      spacing: 8

      // Collapsed: summary and body on one line.
      RowLayout {
        visible: !root.expanded && !(root.single && root.entry.notification.body === "")
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

        Text {
          Layout.fillWidth: true
          text: root.entry.notification.body.replace(/\n/g, " ")
          textFormat: Text.StyledText
          color: Theme.fg
          linkColor: Theme.accent
          // Eliding StyledText takes wrapping to one line.
          wrapMode: Text.Wrap
          maximumLineCount: 1
          elide: Text.ElideRight
          font: Theme.body
        }
      }

      // Expanded: the whole notification.
      RowLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          // A lone notification's image is the group's icon.
          visible: !root.single && source != ""
          Layout.alignment: Qt.AlignTop
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

            Text {
              Layout.alignment: Qt.AlignTop
              text: Notifs.age(root.entry.time)
              color: Theme.fgDim
              font: Theme.caption
            }
          }

          Text {
            id: body

            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.notification.body
            textFormat: Text.StyledText
            color: Theme.fg
            linkColor: Theme.accent
            wrapMode: Text.Wrap
            font: Theme.body
            onLinkActivated: link => {
              Notifs.openUrl(link);
              Panels.close();
            }

            HoverHandler {
              cursorShape: body.hoveredLink ? Qt.PointingHandCursor : undefined
            }
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
