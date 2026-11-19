pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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
  readonly property bool expandable: expanded || unfolded || !single || newest.buttons.length > 0 || newest.progress !== undefined || title.truncated || (root.first?.truncated ?? false)
  readonly property int iconSize: 32
  readonly property int padding: 8
  readonly property int rows: 3
  // Three lines tall however few it holds, so the stack is even.
  readonly property real threeLines: heading.height + (rows - 1) * body.height
  // Its text wraps only once the list gives it a width, a frame or two in; eased, that slid it as the center opened.
  property bool settled: false
  // Laid out expanded, until collapsing has eased the card down, so collapsing animates as expanding does.
  property bool unfolded: false
  // Expanded, the cards inside keep off its top and bottom edges as they keep off its sides.
  readonly property real inset: expanded ? 8 : 0
  // The text centred while collapsed and at the top expanded, easing between them; the icon keeps level with the title.
  property real textOffset: expanded ? inset : Math.max(0, (threeLines - column.implicitHeight) / 2)

  Behavior on textOffset {
    enabled: root.settled

    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    interval: 250
    running: true
    onTriggered: root.settled = true
  }

  Timer {
    id: fold

    interval: 200
    onTriggered: {
      root.unfolded = false;
      titleFade.play();
    }
  }

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
  onExpandedChanged: {
    fold.stop();
    if (expanded) unfolded = true;
    else fold.start();
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
    // A hand only where the click opens something, an arrow where it only dismisses.
    restCursor: root.expandable || root.newest?.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
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

    readonly property real content: Math.max(row.implicitHeight, root.threeLines)

    width: root.width
    height: root.expanded || !root.unfolded ? content + root.padding * 2 + root.inset : root.threeLines + root.padding * 2
    radius: Theme.cardRadius
    color: {
      const hovered = !root.expanded && hover.hovered;
      if (root.critical) return hovered ? Theme.criticalCardHover : Theme.criticalCard;
      return hovered ? Theme.cardHover : Theme.card;
    }
    clip: true

    Behavior on height {
      enabled: root.settled

      NumberAnimation {
        duration: 200
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    HoverHandler {
      id: hover
    }

    RowLayout {
      id: row

      x: root.padding
      y: root.padding
      width: parent.width - 2 * root.padding
      spacing: 10

      NotificationIcon {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: root.textOffset
        entry: root.newest
        // A group shows the app, a lone notification its picture.
        image: root.single ? root.newest?.notification.image ?? "" : ""
        size: root.iconSize

        // The app's count, where its name used to say it.
        Rectangle {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -4
          }
          visible: !root.single
          implicitWidth: Math.max(height, count.implicitWidth + 9)
          implicitHeight: 18
          radius: height / 2
          color: Theme.slider
          border.width: 2
          border.color: Theme.bg

          Text {
            id: count

            anchors.centerIn: parent
            text: root.shown.length
            color: Theme.bg
            font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: Font.Bold })
          }
        }
      }

      ColumnLayout {
        id: column

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: root.textOffset
        spacing: root.unfolded && !root.single ? 6 : 0

        Behavior on spacing {
          enabled: root.settled

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
            wrapMode: root.unfolded ? Text.Wrap : Text.NoWrap
            maximumLineCount: root.unfolded ? 6 : 1
            elide: Text.ElideRight
            font: Theme.heading

            ElideFade {
              id: titleFade
            }
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
            values: root.unfolded ? root.shown : root.shown.slice(0, root.rows)
          }

          NotificationItem {
            required property NotifEntry modelData
            required property int index

            Layout.fillWidth: true
            entry: modelData
            expanded: root.unfolded
            single: root.single
            lines: root.rows - 1
            closable: !root.unfolded && index === 0 && hover.hovered
            settled: root.settled
            onClosed: root.slideAway(false)
          }
        }

        // Its notifications cover it once expanded, so collapsing has a button of its own.
        Button {
          Layout.alignment: Qt.AlignRight
          visible: root.unfolded && !root.single
          flat: true
          text: "Collapse"
          expander: true
          open: true
          onClicked: root.expanded = false
        }
      }

      // On every card so the ages line up, overhanging the first line so the arrow costs no height.
      Item {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: root.textOffset
        implicitWidth: 24
        implicitHeight: column.implicitHeight

        ExpanderArrow {
          anchors.horizontalCenter: parent.horizontalCenter
          y: heading.height / 2 - height / 2
          visible: root.expandable
          open: root.expanded
        }
      }
    }
  }
}
