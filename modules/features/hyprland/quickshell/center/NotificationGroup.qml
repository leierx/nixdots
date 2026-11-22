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
  // What a test clicks by: the app whose group this is.
  objectName: newest ? "group:" + (newest.notification.appName ?? "") : ""

  // Kept once the app's last entry has gone, so the group fades out whole.
  property var shown: []
  onEntriesChanged: {
    if (entries.length === 0) return;
    shown = entries;
    swipe.restore();
  }
  Component.onCompleted: shown = entries

  readonly property NotifEntry newest: shown[0] ?? null
  readonly property bool single: shown.length === 1
  // Critical ones first, so one is never hidden below the collapsed lines.
  readonly property var ordered: [...shown.filter(e => e.critical), ...shown.filter(e => !e.critical)]
  readonly property bool expandable: expanded || unfolded || !single || newest.buttons.length > 0 || newest.progress !== undefined || title.truncated || (root.first?.truncated ?? false)
  readonly property int iconSize: 32
  // How far its card is off to a side, for the probe: 0 at rest.
  readonly property real slid: card.x
  readonly property int padding: 8
  readonly property int rows: 3
  // Three lines tall however few it holds, so the stack is even.
  readonly property real threeLines: heading.height + (rows - 1) * body.height
  // Its text wraps only once the list gives it a width, a frame or two in; eased, that slid it as the center opened.
  property bool settled: false
  // Laid out expanded, until collapsing has eased the card down, so collapsing animates as expanding does.
  property bool unfolded: false
  // Expanded, a group's cards keep off its top and bottom edges as they keep off its sides.
  readonly property real inset: expanded && !single ? 8 : 0
  // The text centred while collapsed; a group's goes to the top expanded, a lone one's stays put, so its card only pulls up and drops down. The icon keeps level with the title.
  property real textOffset: single ? Math.max(0, (threeLines - heading.height - (root.first?.collapsedHeight ?? 0)) / 2) : expanded ? inset : Math.max(0, (threeLines - column.implicitHeight) / 2)

  Behavior on textOffset {
    enabled: root.settled

    NumberAnimation {
      duration: Theme.popupTime
      easing.type: Easing.OutQuad
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
    onTriggered: root.unfolded = false
  }

  // itemAt() is not reactive, so the first row is looked up again as rows come and go.
  property NotificationItem first: null

  implicitHeight: card.height
  activeFocusOnTab: true
  Keys.onReturnPressed: swipe.tapped()
  Keys.onSpacePressed: swipe.tapped()
  Keys.onDeletePressed: root.slideAway(false)

  function findFirst(): void {
    first = items.itemAt(0);
  }

  function slideAway(left: bool): void {
    const dismissals = root.shown.map(entry => entry.dismissal());
    swipe.slideAway(left, () => {
      dismissals.forEach(dismiss => dismiss());
      return root.entries.length === 0;
    });
  }

  function dismiss(): void {
    for (const dismissal of root.shown.map(entry => entry.dismissal())) dismissal();
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
    onTapped: {
      if (root.expandable) {
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
    // Three lines folded, whatever a narrow center wraps inside them.
    height: root.expanded ? content + root.padding * 2 + root.inset : root.threeLines + root.padding * 2
    radius: Theme.messageRadius
    color: !root.expanded && hover.hovered ? Theme.messageHoverBg : Theme.messageBg
    // A lone critical notification is marked as its popup is; in a group, only its own box or line is.
    border.width: root.single && root.newest?.critical ? 1 : 0
    border.color: Theme.destructive
    clip: true

    Behavior on height {
      enabled: root.settled

      NumberAnimation {
        duration: Theme.popupTime
        easing.type: Easing.OutQuad
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.quickTime
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
        image: root.single ? root.newest?.image ?? "" : ""
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
          color: Theme.sliderKnob
          border.width: 2
          border.color: Theme.messageBg

          Text {
            id: count

            anchors.centerIn: parent
            text: root.shown.length
            color: Theme.panelBg
            font: Theme.captionHeading
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
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
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
            text: root.newest?.summary || "Notification"
            textFormat: Text.PlainText
            color: Theme.fg
            wrapMode: root.unfolded ? Text.Wrap : Text.NoWrap
            maximumLineCount: root.unfolded ? 6 : 1
            elide: Text.ElideRight
            font: Theme.heading
          }

          NotificationStamp {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
            entry: root.newest
            closable: true
            expandable: root.expandable
            pointing: root.expanded ? "up" : "down"
            onClosed: root.slideAway(false)
          }
        }

        Repeater {
          id: items

          onItemAdded: Qt.callLater(root.findFirst)
          onItemRemoved: Qt.callLater(root.findFirst)
          model: ScriptModel {
            values: root.unfolded ? root.ordered : root.ordered.slice(0, root.rows)
          }

          NotificationItem {
            required property NotifEntry modelData
            required property int index

            Layout.fillWidth: true
            entry: modelData
            expanded: root.unfolded
            single: root.single
            lines: root.rows - 1
            closable: !root.unfolded && index === 0
            expander: root.expandable && !root.unfolded && index === 0
            settled: root.settled
            onClosed: root.slideAway(false)
          }
        }
      }

      // An expanded group's way back, beside its first card; collapsed, its first line's stamp holds the arrow.
      Item {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: root.textOffset
        visible: root.unfolded && !root.single
        implicitWidth: 24
        implicitHeight: heading.height

        ExpanderArrow {
          anchors.centerIn: parent
          pointing: "up"
        }
      }
    }
  }

  FocusRing {
    corner: Theme.messageRadius
    on: root.activeFocus
  }
}
