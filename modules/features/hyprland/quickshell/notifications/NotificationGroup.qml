pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common
import "swipe.js" as Swipe

// One app's notifications in the center, grouped the way end-4's dots do: the
// app's icon and name, the latest time and a count over its two newest
// notifications, a line each. Expanded, each notification gets its own card.
// A click expands the group, or runs a lone notification's default action; a
// right click expands and collapses it; a swipe or a middle click dismisses
// it, and once expanded, the same on a notification dismisses just that one.
Item {
  id: root

  // Newest first.
  required property var entries
  // How far a swipe in the list moves it.
  property real lean: 0
  property bool expanded: false

  signal swipeMoved(real distance)
  signal swipeEnded()

  readonly property bool single: entries.length === 1
  readonly property Notification newest: entries[0]?.notification ?? null
  readonly property NotificationAction defaultAction: single ? newest?.actions.find(a => a.identifier === "default") ?? null : null
  readonly property bool critical: entries.some(e => e.critical)
  readonly property string appIcon: Notifs.appIcon(newest)
  readonly property bool showImage: single && !!newest?.image
  readonly property int iconSize: Theme.px(40)
  readonly property int pad: Theme.px(10)

  // The notification being swiped inside it, by index, and how far.
  property int swiped: -1
  property real swipeDistance: 0

  implicitHeight: card.height

  function slideAway(left) {
    card.x = card.x;
    away.to = (left ? -1 : 1) * (width + Theme.px(20));
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
      for (const entry of root.entries.slice()) entry.notification.dismiss();
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
      if (button === Qt.MiddleButton) {
        root.slideAway(false);
      } else if (button === Qt.RightButton || root.expanded) {
        root.expanded = !root.expanded;
      } else if (root.defaultAction) {
        root.defaultAction.invoke();
        Panels.close();
      } else {
        root.expanded = true;
      }
    }
  }

  Rectangle {
    id: card

    x: root.lean
    width: root.width
    height: row.implicitHeight + root.pad * 2
    radius: Theme.radius
    color: !root.expanded && hover.hovered ? Theme.selected : Theme.raised
    border.width: root.critical ? 1 : 0
    border.color: Theme.urgent
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

      cursorShape: root.expanded ? Qt.ArrowCursor : Qt.PointingHandCursor
    }

    RowLayout {
      id: row

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.pad
      }
      spacing: Theme.px(12)

      Item {
        Layout.alignment: Qt.AlignTop
        implicitWidth: root.iconSize
        implicitHeight: root.iconSize

        Rectangle {
          anchors.fill: parent
          visible: !root.showImage
          radius: width / 2
          color: root.critical ? Theme.urgent : Theme.bg
        }

        IconImage {
          anchors.centerIn: parent
          visible: !root.showImage && root.appIcon !== ""
          source: root.appIcon
          implicitSize: Math.round(root.iconSize * 0.7)
        }

        Text {
          anchors.centerIn: parent
          visible: !root.showImage && root.appIcon === ""
          text: (root.newest?.appName || "?")[0].toUpperCase()
          color: Theme.fg
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontTitle
            weight: Font.Bold
          }
        }

        ClippingRectangle {
          anchors.fill: parent
          visible: root.showImage
          radius: width / 2
          color: "transparent"

          Image {
            anchors.fill: parent
            source: root.showImage ? root.newest.image : ""
            sourceSize {
              width: root.iconSize * 2
              height: root.iconSize * 2
            }
            fillMode: Image.PreserveAspectCrop
            // The image provider reuses URLs for different notifications.
            cache: false
          }
        }

        // The app's icon in the corner of a notification's image.
        IconImage {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -Theme.px(2)
          }
          visible: root.showImage && root.appIcon !== ""
          source: root.appIcon
          implicitSize: Math.round(root.iconSize * 0.45)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.expanded ? Theme.px(6) : Theme.px(2)

        Behavior on spacing {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.minimumHeight: Theme.px(24)
          spacing: Theme.px(8)

          // A lone notification's summary, or the app's name over several.
          Text {
            Layout.fillWidth: true
            text: (root.single ? root.newest?.summary : root.newest?.appName) || "Notification"
            textFormat: Text.PlainText
            color: root.single ? Theme.fg : Theme.fgSoft
            elide: Text.ElideRight
            font {
              family: Theme.fontFamily
              pixelSize: root.single ? Theme.fontBody : Theme.fontSmall
              weight: Font.DemiBold
            }
          }

          Text {
            text: Notifs.age(root.entries[0]?.time ?? Notifs.now)
            color: Theme.fgDim
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontSmall
            }
          }

          Rectangle {
            implicitWidth: Math.max(implicitHeight, pill.implicitWidth + Theme.px(14))
            implicitHeight: Theme.px(24)
            radius: height / 2
            color: pillArea.containsMouse ? Theme.highlight : Theme.bg

            Row {
              id: pill

              anchors.centerIn: parent
              spacing: Theme.px(4)

              Text {
                visible: !root.single
                anchors.verticalCenter: parent.verticalCenter
                text: root.entries.length
                color: Theme.fg
                font {
                  family: Theme.fontFamily
                  pixelSize: Theme.fontSmall
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "▾"
                color: Theme.fg
                rotation: root.expanded ? 180 : 0
                font {
                  family: Theme.glyphFamily
                  pixelSize: Theme.fontSmall
                }

                Behavior on rotation {
                  NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                  }
                }
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
            values: root.expanded ? root.entries : root.entries.slice(0, 2)
          }

          NotificationItem {
            required property NotifEntry modelData
            required property int index

            Layout.fillWidth: true
            entry: modelData
            expanded: root.expanded
            single: root.single
            // The second line, with more behind it.
            dimmed: !root.expanded && index === 1 && root.entries.length > 2
            lean: Swipe.lean(index, root.swiped, root.swipeDistance, swipe.threshold)
            onSwipeMoved: distance => {
              root.swiped = index;
              root.swipeDistance = distance;
            }
            onSwipeEnded: {
              root.swiped = -1;
              root.swipeDistance = 0;
            }
            onCollapse: root.expanded = false
          }
        }
      }
    }
  }
}
