pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.notifications

Item {
  id: root

  required property var entries
  property bool expanded: false

  // Kept once the app's last entry has gone, so the group fades out whole.
  property var shown: []
  onEntriesChanged: {
    if (entries.length > 0) shown = entries;
  }
  Component.onCompleted: shown = entries

  readonly property NotifEntry newest: shown[0] ?? null
  readonly property bool single: shown.length === 1
  readonly property bool critical: shown.some(e => e.critical)
  readonly property bool showImage: single && newest.notification.image !== ""
  readonly property bool expandable: !single || newest.buttons.length > 0 || newest.progress !== undefined || title.truncated || (root.first?.truncated ?? false)
  readonly property int iconSize: 40

  // itemAt() is not reactive, so the first row is looked up again as rows come and go.
  property NotificationItem first: null

  implicitHeight: card.height

  function findFirst(): void {
    first = items.itemAt(0);
  }

  function slideAway(left: bool): void {
    const dismissals = root.shown.map(entry => entry.dismissal());
    swipe.slideAway(left, () => dismissals.forEach(dismiss => dismiss()));
  }

  onSingleChanged: {
    if (single) expanded = false;
  }

  // Under the card, so its buttons, links and notifications come first.
  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: card
    swipeEnabled: !root.expanded || root.single
    onSwiped: left => root.slideAway(left)
    onTapped: button => {
      if (button !== Qt.LeftButton) {
        root.slideAway(false);
      } else if (root.expandable) {
        root.expanded = !root.expanded;
      } else if (root.newest.defaultAction) {
        root.newest.defaultAction.invoke();
        Panels.close();
      }
    }
  }

  Rectangle {
    id: card

    width: root.width
    height: row.implicitHeight + Theme.padding * 2
    radius: Theme.cardRadius
    color: !root.expanded && hover.hovered ? Theme.cardHover : Theme.card
    border.width: root.critical ? 1 : 0
    border.color: Theme.destructive
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
    }

    RowLayout {
      id: row

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
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
          visible: !root.showImage && !!root.newest?.appIcon
          source: root.newest ? root.newest.appIcon : ""
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

        IconImage {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -2
          }
          visible: root.showImage && !!root.newest?.appIcon
          source: root.newest ? root.newest.appIcon : ""
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
          spacing: 6

          // A lone notification's summary is the header, wrapped in full once expanded.
          Text {
            id: title

            Layout.fillWidth: root.single
            text: (root.single ? root.newest.notification.summary : root.newest?.notification.appName) || "Notification"
            textFormat: Text.PlainText
            color: root.single ? Theme.fg : Theme.fgDim
            wrapMode: root.single && root.expanded ? Text.Wrap : Text.NoWrap
            maximumLineCount: root.single && root.expanded ? 6 : 1
            elide: Text.ElideRight
            font: root.single ? Theme.heading : Theme.captionHeading
          }

          NotificationAge {
            Layout.alignment: Qt.AlignTop
            visible: root.single
            entry: root.newest
          }

          Text {
            Layout.fillWidth: true
            visible: !root.single
            text: root.shown.length
            color: Theme.fgDim
            font: Theme.caption
          }

          ExpandButton {
            Layout.alignment: Qt.AlignTop
            visible: root.expandable
            open: root.expanded
            onClicked: root.expanded = !root.expanded
          }

          // Only under the pointer, as GNOME shows it.
          CloseButton {
            Layout.alignment: Qt.AlignTop
            opacity: hover.hovered ? 1 : 0
            enabled: hover.hovered
            onClicked: root.slideAway(false)
          }
        }

        Repeater {
          id: items

          onItemAdded: Qt.callLater(root.findFirst)
          onItemRemoved: Qt.callLater(root.findFirst)
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
            dimmed: !root.expanded && index === 1 && root.shown.length > 2
          }
        }
      }
    }
  }
}
