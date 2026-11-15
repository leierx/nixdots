pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common

// One notification: its app and age, then the image, summary and body, a
// progress bar if the app sends one, and the actions. A click runs the default
// action; a right click or a swipe dismisses it.
Item {
  id: root

  required property NotifEntry entry
  // In the notification center, cards sit flat on the center's panel.
  property bool flat: false
  // On top of a folded stack, a click unfolds the stack instead.
  property bool folded: false

  signal unfold()

  readonly property Notification notification: entry?.notification ?? null
  readonly property NotificationAction defaultAction: notification?.actions.find(a => a.identifier === "default") ?? null
  readonly property var actions: notification?.actions.filter(a => a.identifier !== "default") ?? []
  // Three actions fit in a row; with more, the third button opens the rest.
  readonly property bool overflow: actions.length > 3
  readonly property var progress: notification?.hints.value
  readonly property string appIcon: iconSource(notification?.appIcon) || (notification?.appName ? iconSource(DesktopEntries.heuristicLookup(notification.appName)?.icon) : "")
  readonly property int imageSize: Theme.px(40)

  readonly property string age: {
    const seconds = (Notifs.now - (entry?.time ?? Notifs.now)) / 1000;
    if (seconds < 60) return "now";
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
    return Qt.formatDate(entry.time, "d MMM");
  }

  property bool expanded: false
  property bool moreOpen: false

  implicitHeight: card.implicitHeight

  function iconSource(icon) {
    if (!icon) return "";
    if (icon.startsWith("file://")) return icon;
    if (icon.startsWith("/")) return `file://${icon}`;
    return Quickshell.iconPath(icon, true);
  }

  function activate() {
    if (folded) {
      unfold();
    } else if (defaultAction) {
      defaultAction.invoke();
      if (flat) Panels.close();
    } else if (!flat) {
      entry.popup = false;
    }
  }

  component ActionButton: Rectangle {
    id: button

    property alias text: label.text
    property string glyph: ""

    signal clicked()

    implicitHeight: Theme.px(34)
    radius: Theme.px(8)
    color: area.containsMouse ? Theme.selected : root.flat ? Theme.bg : Theme.raised

    Row {
      anchors.centerIn: parent
      spacing: Theme.px(6)

      Text {
        id: label

        width: Math.min(implicitWidth, button.width - Theme.px(20) - (glyph.visible ? glyph.width + parent.spacing : 0))
        color: Theme.fg
        elide: Text.ElideRight
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontBody
        }
      }

      Text {
        id: glyph

        visible: button.glyph !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: button.glyph
        color: Theme.fgSoft
        font {
          family: Theme.glyphFamily
          pixelSize: Theme.fontBody
        }
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  Rectangle {
    id: card

    width: root.width
    implicitHeight: content.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: !root.flat ? Theme.bg : hover.hovered ? Theme.selected : Theme.raised
    border.width: root.flat && !root.entry?.critical ? 0 : 1
    border.color: root.entry?.critical ? Theme.urgent : Theme.border
    opacity: 1 - Math.abs(x) / width

    Behavior on x {
      enabled: !swipe.drag.active

      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    HoverHandler {
      id: hover

      onHoveredChanged: {
        if (!root.flat) root.entry.hovered = hovered;
      }
    }

    // Under the buttons and links, so they get their clicks first.
    MouseArea {
      id: swipe

      property bool swiped: false

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: root.flat ? Qt.PointingHandCursor : Qt.ArrowCursor
      drag {
        target: card
        axis: Drag.XAxis
        // Popups only leave towards the screen edge.
        minimumX: root.flat ? -card.width : 0
        maximumX: card.width
      }
      onPressed: swiped = false
      onPositionChanged: {
        if (drag.active) swiped = true;
      }
      onReleased: {
        if (!swiped) return;
        if (Math.abs(card.x) > card.width / 3) root.notification.dismiss();
        else card.x = 0;
      }
      onClicked: mouse => {
        if (swiped) return;
        if (mouse.button === Qt.RightButton) root.notification.dismiss();
        else root.activate();
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
      spacing: Theme.px(8)

      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(8)

        IconImage {
          visible: root.appIcon !== ""
          source: root.appIcon
          implicitSize: Theme.px(16)
        }

        Text {
          Layout.fillWidth: true
          text: root.notification?.appName || "Notification"
          color: Theme.fgDim
          elide: Text.ElideRight
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSmall
          }
        }

        Text {
          text: root.age
          color: Theme.fgDim
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSmall
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(12)

        ClippingRectangle {
          visible: !!root.notification?.image
          Layout.alignment: Qt.AlignTop
          implicitWidth: root.imageSize
          implicitHeight: root.imageSize
          radius: Theme.px(8)
          color: "transparent"

          Image {
            anchors.fill: parent
            source: root.notification?.image ?? ""
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
              pixelSize: Theme.fontTitle
              weight: Font.DemiBold
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
            maximumLineCount: root.expanded ? 1000 : 4
            elide: Text.ElideRight
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontBody
            }
            onLinkActivated: link => Notifs.openUrl(link)

            HoverHandler {
              cursorShape: body.hoveredLink ? Qt.PointingHandCursor : undefined
            }
          }

          Text {
            visible: body.truncated || root.expanded
            text: root.expanded ? "Show less" : "Show more"
            color: Theme.accent
            font {
              family: Theme.fontFamily
              pixelSize: Theme.fontSmall
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.expanded = !root.expanded
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: root.progress !== undefined
        implicitHeight: Theme.px(6)
        radius: height / 2
        color: root.flat ? Theme.bg : Theme.selected

        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.progress ?? 0)) / 100
          height: parent.height
          radius: parent.radius
          color: Theme.accent
        }
      }

      RowLayout {
        Layout.fillWidth: true
        visible: root.actions.length > 0
        spacing: Theme.px(8)

        Repeater {
          model: root.overflow ? root.actions.slice(0, 2) : root.actions

          ActionButton {
            required property NotificationAction modelData

            Layout.fillWidth: true
            text: modelData.text
            onClicked: modelData.invoke()
          }
        }

        ActionButton {
          visible: root.overflow
          Layout.fillWidth: true
          text: "More"
          glyph: root.moreOpen ? "▴" : "▾"
          onClicked: root.moreOpen = !root.moreOpen
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: root.overflow && root.moreOpen
        spacing: Theme.px(4)

        Repeater {
          model: root.overflow ? root.actions.slice(2) : []

          ActionButton {
            required property NotificationAction modelData

            Layout.fillWidth: true
            text: modelData.text
            onClicked: modelData.invoke()
          }
        }
      }
    }
  }
}
