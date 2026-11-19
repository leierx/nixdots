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
  readonly property int iconSize: 32
  readonly property int padding: 8
  readonly property int rows: 3
  readonly property bool badged: showImage && newest.appIcon !== "" && newest.appIcon !== newest.notification.image
  // Three lines tall however few it holds, so the stack is even.
  readonly property real minHeight: expanded ? 0 : heading.height + (rows - 1) * body.height

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

  FontMetrics {
    id: heading

    font: Theme.heading
  }

  FontMetrics {
    id: body

    font: Theme.body
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
      } else {
        root.slideAway(false);
      }
    }
  }

  Rectangle {
    id: card

    readonly property real content: Math.max(row.implicitHeight, root.minHeight)

    width: root.width
    height: content + root.padding * 2
    radius: Theme.cardRadius
    color: {
      const hovered = !root.expanded && hover.hovered;
      if (root.critical) return hovered ? Theme.criticalCardHover : Theme.criticalCard;
      return hovered ? Theme.cardHover : Theme.card;
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
    }

    RowLayout {
      id: row

      x: root.padding
      y: root.padding + (card.content - implicitHeight) / 2
      width: parent.width - 2 * root.padding
      spacing: 10

      Item {
        Layout.alignment: root.expanded ? Qt.AlignTop : Qt.AlignVCenter
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
          implicitSize: 22
        }

        Text {
          anchors.centerIn: parent
          visible: !root.showImage && root.newest?.appIcon === ""
          text: (root.newest?.notification.appName || "?")[0].toUpperCase()
          color: Theme.fg
          font: Theme.heading
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
            margins: -3
          }
          visible: root.badged
          source: root.badged ? root.newest.appIcon : ""
          implicitSize: 16
        }

        // The app's count, where its name used to say it.
        Rectangle {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -4
          }
          visible: !root.single
          implicitWidth: Math.max(height, count.implicitWidth + 8)
          implicitHeight: 16
          radius: height / 2
          color: Theme.slider
          border.width: 2
          border.color: Theme.bg

          Text {
            id: count

            anchors.centerIn: parent
            text: root.shown.length
            color: Theme.bg
            font: Theme.captionHeading
          }
        }
      }

      ColumnLayout {
        id: column

        Layout.fillWidth: true
        Layout.alignment: root.expanded ? Qt.AlignTop : Qt.AlignVCenter
        spacing: root.expanded ? 6 : 0

        Behavior on spacing {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }

        // A lone notification's summary heads it, wrapped in full once expanded.
        RowLayout {
          Layout.fillWidth: true
          visible: root.single
          spacing: 8

          Text {
            id: title

            Layout.fillWidth: true
            text: root.newest?.notification.summary || "Notification"
            textFormat: Text.PlainText
            color: Theme.fg
            wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
            maximumLineCount: root.expanded ? 6 : 1
            elide: Text.ElideRight
            font: Theme.heading
          }

          NotificationStamp {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
            entry: root.newest
            closable: root.expandable && hover.hovered
            onClosed: root.slideAway(false)
          }
        }

        Repeater {
          id: items

          onItemAdded: Qt.callLater(root.findFirst)
          onItemRemoved: Qt.callLater(root.findFirst)
          model: ScriptModel {
            values: root.expanded ? root.shown : root.shown.slice(0, root.rows)
          }

          NotificationItem {
            required property NotifEntry modelData
            required property int index

            Layout.fillWidth: true
            entry: modelData
            expanded: root.expanded
            single: root.single
            lines: root.rows - 1
            closable: !root.expanded && index === 0 && hover.hovered
            onClosed: root.slideAway(false)
          }
        }
      }

      // On every card so the ages line up, overhanging the first line so the arrow costs no height.
      Item {
        Layout.alignment: column.Layout.alignment
        implicitWidth: 24
        implicitHeight: column.implicitHeight

        ExpandButton {
          anchors.horizontalCenter: parent.horizontalCenter
          y: heading.height / 2 - height / 2
          visible: root.expandable
          open: root.expanded
          onClicked: root.expanded = !root.expanded
        }
      }
    }
  }
}
