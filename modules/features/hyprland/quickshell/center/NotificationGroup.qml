pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.notifications
import "swipe.js" as Swipe

// One app's notifications in the center, grouped the way end-4's dots do: the
// app's icon and name, the latest time and a count over its two newest
// notifications, a line each. Expanded, each notification gets its own card.
// A click on a lone notification runs its default action, or dismisses it if
// it has none and no buttons to choose from; a click on several expands or
// collapses them. A right or middle click or a swipe dismisses the group, and
// once expanded, the same on a notification dismisses just that one.
Item {
  id: root

  // Newest first.
  required property var entries
  // How far a swipe in the list moves it.
  property real lean: 0
  property bool expanded: false

  // The entries last shown, kept once the app's last one has gone so the group
  // fades out whole.
  property var shown: []
  onEntriesChanged: {
    if (entries.length > 0) shown = entries;
  }
  Component.onCompleted: shown = entries

  signal swipeMoved(real distance)
  signal swipeEnded()

  readonly property NotifEntry newest: shown[0] ?? null
  readonly property bool single: shown.length === 1
  readonly property bool critical: shown.some(e => e.critical)
  readonly property bool showImage: single && newest.notification.image !== ""
  readonly property int iconSize: 40
  readonly property int pad: 12

  // The notification being swiped inside it, by index, and how far.
  property int swiped: -1
  property real swipeDistance: 0

  implicitHeight: card.height

  function slideAway(left) {
    card.x = card.x;
    away.to = (left ? -1 : 1) * (width + 20);
    away.start();
  }

  // Collapses as its last notification but one goes.
  onSingleChanged: {
    if (single) expanded = false;
  }

  NumberAnimation {
    id: away

    target: card
    property: "x"
    duration: 200
    easing.type: Easing.InCubic
    // Dismissing removes the entry, so walk a copy.
    onFinished: {
      for (const entry of root.shown.slice()) entry.notification.dismiss();
    }
  }

  // Under the card, so its buttons, links and notifications come first.
  SwipeArea {
    id: swipe

    anchors.fill: parent
    swipeEnabled: !root.expanded
    onDistanceChanged: {
      if (dragging) root.swipeMoved(distance);
    }
    onDraggingChanged: {
      if (!dragging) root.swipeEnded();
    }
    onSwiped: left => root.slideAway(left)
    onTapped: button => {
      if (button !== Qt.LeftButton) {
        root.slideAway(false);
      } else if (!root.single) {
        root.expanded = !root.expanded;
      } else if (root.newest.defaultAction) {
        root.newest.defaultAction.invoke();
        Panels.close();
      } else if (root.newest.clickDismisses) {
        root.slideAway(false);
      }
    }
  }

  Rectangle {
    id: card

    x: root.lean
    width: root.width
    height: row.implicitHeight + root.pad * 2
    radius: Theme.cardRadius
    color: !root.expanded && hover.hovered ? Theme.cardHover : Theme.card
    border.width: root.critical ? 1 : 0
    border.color: Theme.destructive
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

    HoverHandler {
      id: hover

      cursorShape: !root.single || root.newest?.defaultAction || root.newest?.clickDismisses ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    RowLayout {
      id: row

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.pad
      }
      spacing: 12

      Item {
        Layout.alignment: Qt.AlignTop
        implicitWidth: root.iconSize
        implicitHeight: root.iconSize

        Rectangle {
          anchors.fill: parent
          visible: !root.showImage
          radius: width / 2
          color: root.critical ? Theme.destructiveBg : Theme.card
        }

        IconImage {
          anchors.centerIn: parent
          visible: !root.showImage && source != ""
          source: root.newest?.appIcon ?? ""
          implicitSize: 28
        }

        Text {
          anchors.centerIn: parent
          visible: !root.showImage && root.newest?.appIcon === ""
          text: (root.newest?.notification.appName || "?")[0].toUpperCase()
          color: Theme.fg
          font: Theme.title4
        }

        NotificationImage {
          anchors.fill: parent
          visible: root.showImage
          source: root.showImage ? root.newest.notification.image : ""
          size: root.iconSize
          radius: width / 2
        }

        // The app's icon in the corner of a notification's image.
        IconImage {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -2
          }
          visible: root.showImage && source != ""
          source: root.newest?.appIcon ?? ""
          implicitSize: 18
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.expanded ? 6 : 2

        Behavior on spacing {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.minimumHeight: 24
          spacing: 8

          // A lone notification's summary, or the app's name over several.
          Text {
            Layout.fillWidth: true
            text: (root.single ? root.newest.notification.summary : root.newest?.notification.appName) || "Notification"
            textFormat: Text.PlainText
            color: root.single ? Theme.fg : Theme.fgDim
            elide: Text.ElideRight
            font: root.single ? Theme.heading : Theme.captionHeading
          }

          Text {
            text: root.newest ? Notifs.age(root.newest.time) : ""
            color: Theme.fgDim
            font: Theme.caption
          }

          // GTK's menu button: the count and the arrow, as libadwaita draws a
          // label with an arrow; with no count it is an image button.
          Rectangle {
            implicitWidth: pill.implicitWidth
            implicitHeight: 34
            radius: Theme.buttonRadius
            color: pillArea.containsMouse ? Theme.buttonHover : Theme.button

            Row {
              id: pill

              anchors.centerIn: parent
              leftPadding: root.single ? 9 : 10
              rightPadding: root.single ? 9 : 10
              spacing: 6

              Text {
                visible: !root.single
                anchors.verticalCenter: parent.verticalCenter
                text: root.shown.length
                color: Theme.fg
                font: Theme.heading
              }

              ExpanderArrow {
                anchors.verticalCenter: parent.verticalCenter
                open: root.expanded
              }
            }

            MouseArea {
              id: pillArea

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.expanded = !root.expanded
            }
          }
        }

        Repeater {
          model: ScriptModel {
            values: root.expanded ? root.shown : root.shown.slice(0, 2)
          }

          NotificationItem {
            required property NotifEntry modelData
            required property int index

            Layout.fillWidth: true
            entry: modelData
            expanded: root.expanded
            single: root.single
            // The second line, with more behind it.
            dimmed: !root.expanded && index === 1 && root.shown.length > 2
            lean: Swipe.lean(index, root.swiped, root.swipeDistance, swipe.threshold)
            onSwipeMoved: distance => {
              root.swiped = index;
              root.swipeDistance = distance;
            }
            onSwipeEnded: {
              root.swiped = -1;
              root.swipeDistance = 0;
            }
          }
        }
      }
    }
  }
}
