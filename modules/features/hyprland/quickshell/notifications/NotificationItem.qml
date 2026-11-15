pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common

// One notification inside a group. Collapsed, a line of its summary and body;
// expanded, a card of its own with the image, the whole body and the actions,
// which a click runs the default action of, a middle click or a swipe
// dismisses, and a right click collapses the group again. A group's only
// notification has its summary in the group's header and goes without a card.
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
  signal collapse()

  readonly property Notification notification: entry?.notification ?? null
  readonly property NotificationAction defaultAction: notification?.actions.find(a => a.identifier === "default") ?? null
  readonly property var progress: notification?.hints.value
  readonly property bool boxed: expanded && !single
  readonly property int pad: Theme.px(10)
  readonly property int imageSize: Theme.px(40)

  implicitHeight: box.height

  function slideAway(left) {
    box.x = box.x;
    away.to = (left ? -1 : 1) * (width + Theme.px(20));
    away.start();
  }

  NumberAnimation {
    id: away

    target: box
    property: "x"
    duration: 200
    easing.type: Easing.InCubic
    onFinished: root.notification.dismiss()
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
      if (button === Qt.MiddleButton) {
        root.slideAway(false);
      } else if (button === Qt.RightButton) {
        root.collapse();
      } else if (root.defaultAction) {
        root.defaultAction.invoke();
        Panels.close();
      }
    }
  }

  Rectangle {
    id: box

    x: root.lean
    width: root.width
    height: content.implicitHeight + (root.boxed ? root.pad * 2 : 0)
    radius: Theme.px(8)
    color: !root.boxed ? "transparent" : hover.hovered ? Theme.highlight : Theme.selected
    border.width: root.boxed && root.entry?.critical ? 1 : 0
    border.color: Theme.urgent
    opacity: root.dimmed ? 0.5 : 1
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
      cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.boxed ? root.pad : 0
      }
      spacing: Theme.px(8)

      // Collapsed: summary and body on one line.
      RowLayout {
        visible: !root.expanded && !(root.single && !root.notification?.body)
        Layout.fillWidth: true
        spacing: Theme.px(8)

        Text {
          visible: !root.single
          Layout.maximumWidth: content.width * 0.6
          text: root.notification?.summary ?? ""
          textFormat: Text.PlainText
          color: Theme.fg
          elide: Text.ElideRight
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontBody
            weight: Font.DemiBold
          }
        }

        Text {
          Layout.fillWidth: true
          text: (root.notification?.body ?? "").replace(/\n/g, " ")
          textFormat: Text.StyledText
          color: Theme.fgSoft
          // Eliding StyledText takes wrapping to one line.
          wrapMode: Text.Wrap
          maximumLineCount: 1
          elide: Text.ElideRight
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontBody
          }
        }
      }

      // Expanded: the whole notification.
      RowLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: Theme.px(10)

        ClippingRectangle {
          // A lone notification's image is the group's icon.
          visible: !root.single && !!root.notification?.image
          Layout.alignment: Qt.AlignTop
          implicitWidth: root.imageSize
          implicitHeight: root.imageSize
          radius: Theme.px(8)
          color: "transparent"

          Image {
            anchors.fill: parent
            source: root.single ? "" : root.notification?.image ?? ""
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

          RowLayout {
            visible: !root.single
            Layout.fillWidth: true
            spacing: Theme.px(8)

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
                pixelSize: Theme.fontBody
                weight: Font.DemiBold
              }
            }

            Text {
              Layout.alignment: Qt.AlignTop
              text: Notifs.age(root.entry?.time ?? Notifs.now)
              color: Theme.fgDim
              font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSmall
              }
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
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontBody
            }
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
        visible: root.expanded && root.progress !== undefined
        implicitHeight: Theme.px(6)
        radius: height / 2
        color: Theme.bg

        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.progress ?? 0)) / 100
          height: parent.height
          radius: parent.radius
          color: Theme.accent
        }
      }

      NotificationActions {
        Layout.fillWidth: true
        visible: root.expanded && actions.length > 0
        actions: root.notification?.actions.filter(a => a.identifier !== "default") ?? []
        base: root.boxed ? Theme.raised : Theme.selected
        hover: root.boxed ? Theme.selected : Theme.highlight
      }
    }
  }
}
