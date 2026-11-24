pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.nix

Item {
  id: root

  required property NotifEntry entry

  implicitHeight: card.height

  HoverHandler {
    id: hover
  }

  // The pointer resting on it holds its timeout, so it stays while read.
  Binding {
    target: root.entry
    property: "hovered"
    value: hover.hovered
  }

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: card
    rightOnly: true
    // A hand where the click runs something; an arrow where it only puts the popup away.
    restCursor: root.entry.defaultAction || root.entry.buttons.length === 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
    onSwiped: left => {
      if (!left) swipe.slideAway(false, root.entry.dismissal());
    }
    onTapped: {
      if (root.entry.defaultAction) root.entry.invoke(root.entry.defaultAction);
      else if (root.entry.buttons.length === 1) root.entry.invoke(root.entry.buttons[0]);
      else root.entry.popup = false;
    }
  }

  Card {
    id: card

    width: root.width
    height: content.implicitHeight + 2 * Theme.padding
    radius: Theme.messageRadius
    color: hover.hovered ? Theme.bannerHoverBg : Theme.bannerBg
    border.color: root.entry.critical ? Theme.destructive : Theme.popupBorder
    shadow.spreadBy: 2

    Behavior on color {
      ColorAnimation {
        duration: Theme.quickTime
        easing.type: Easing.OutQuad
      }
    }
    opacity: 1 - x / width

    Behavior on height {
      NumberAnimation {
        duration: Theme.popupTime
        easing.type: Easing.OutQuad
      }
    }

    ClippingRectangle {
      anchors.fill: parent
      radius: card.radius
      color: "transparent"
      visible: root.entry.timeout > 0

      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width * root.entry.remaining
        height: 3
        color: Theme.accentBg
      }
    }

    // The card eases to its new height, so what does not fit yet is cut off.
    Item {
      anchors.fill: parent
      clip: true

      ColumnLayout {
        id: content

        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          margins: Theme.padding
        }
        spacing: Theme.basePadding

        // Shell's banner header: the app, the age, then close; no app icon (ours), as the body shows it already, whole or as the picture's badge.
        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.basePadding

          Text {
            Layout.fillWidth: true
            text: Notifs.clip(root.entry.notification.appName, Notifs.maxApp) || "An app"
            textFormat: Text.PlainText
            maximumLineCount: 1
            elide: Text.ElideRight
            color: Theme.fgDim
            font: Theme.heading
          }

          NotificationAge {
            entry: root.entry
          }

          IconButton {
            objectName: "popup:close"
            tiny: true
            flat: true
            glyph: Symbols.close
            tooltip: "Close"
            onClicked: swipe.slideAway(false, root.entry.dismissal())
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.padding

          NotificationIcon {
            id: icon

            Layout.alignment: Qt.AlignTop
            entry: root.entry
            size: 48
          }

          ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Math.max(0, (icon.height - implicitHeight) / 2)
            spacing: 2

            Text {
              Layout.fillWidth: true
              visible: text !== ""
              text: root.entry.summary
              textFormat: Text.PlainText
              color: Theme.fg
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              font: Theme.heading
            }

            NotificationText {
              Layout.fillWidth: true
              visible: text !== ""
              text: root.entry.body
              maximumLineCount: 4
              onLinkOpened: root.entry.popup = false
            }
          }
        }

        NotificationProgress {
          Layout.fillWidth: true
          visible: root.entry.progress !== undefined
          entry: root.entry
        }

        NotificationActions {
          Layout.fillWidth: true
          actions: root.entry.buttons
          onInvoked: action => root.entry.invoke(action)
        }
      }
    }
  }
}
