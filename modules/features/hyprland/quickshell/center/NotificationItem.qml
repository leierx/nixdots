pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.notifications

Item {
  id: root

  required property NotifEntry entry
  property bool expanded: false
  property bool single: false
  // A lone notification's body has the lines its summary leaves; a group's rows have one each.
  property int lines: 2
  property bool closable: false
  // The group's: nothing eases until it has laid out.
  property bool settled: true

  signal closed()

  readonly property bool boxed: expanded && !single
  readonly property bool truncated: line.truncated
  // A card of its own in an expanded group, opened as a popup is, so a few long ones do not fill the center.
  property bool open: false
  readonly property bool openable: boxed && (open || whole || summary.truncated || body.truncated)
  readonly property int summaryLines: 2
  readonly property int bodyLines: 4
  // Shown whole until closing has eased the card down, so closing animates as opening does.
  property bool whole: false
  // What the text loses on closing, worked out from its lines while it is still whole.
  readonly property real excess: {
    if (open || !whole) return 0;
    const cut = (text, lines) => text.lineCount > lines ? text.implicitHeight * (1 - lines / text.lineCount) : 0;
    return cut(summary, summaryLines) + cut(body, bodyLines);
  }

  // Its group collapsing lays it out anew, which nothing eases.
  onExpandedChanged: {
    if (expanded) return;
    open = false;
    ease.stop();
    eased = 1;
    fold.stop();
    whole = false;
  }
  onOpenChanged: {
    fold.stop();
    if (open) whole = true;
    else fold.start();
    from = box.height;
    ease.restart();
  }

  // Eased from where it was only as it opens or closes, not as its group lays it out anew.
  property real from: 0
  property real eased: 1
  readonly property real natural: content.implicitHeight + (boxed ? 2 * Theme.padding : 0) - excess

  NumberAnimation {
    id: ease

    target: root
    property: "eased"
    from: 0
    to: 1
    duration: root.settled ? Theme.move : 0
    easing.type: Easing.OutCubic
  }

  implicitHeight: box.height

  FontMetrics {
    id: heading

    font: Theme.heading
  }

  Timer {
    id: fold

    interval: 200
    onTriggered: root.whole = false
  }

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: box
    // Collapsed, or alone, the group takes every click.
    enabled: root.boxed
    // Even disabled it would set its arrow over the group's hand.
    restCursor: !root.boxed ? undefined : root.openable || root.entry.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
    onSwiped: left => swipe.slideAway(left, root.entry.dismissal())
    onTapped: {
      if (root.openable) {
        root.open = !root.open;
      } else if (root.entry.defaultAction) {
        root.entry.defaultAction.invoke();
        Panels.close();
      } else {
        swipe.slideAway(false, root.entry.dismissal());
      }
    }
  }

  Rectangle {
    id: box

    width: root.width
    height: root.eased < 1 ? root.from + (root.natural - root.from) * root.eased : root.natural
    radius: Theme.buttonRadius
    color: {
      if (!root.boxed) return "transparent";
      return hover.hovered ? Theme.cardHover : Theme.card;
    }
    border.width: root.boxed && root.entry.critical ? 1 : 0
    border.color: Theme.destructive
    clip: true

    Behavior on color {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    HoverHandler {
      id: hover

      enabled: root.boxed
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: root.boxed ? Theme.padding : 0
      }
      spacing: 6

      RowLayout {
        visible: !root.expanded && !(root.single && root.entry.body === "")
        Layout.fillWidth: true
        spacing: 8

        // A collapsed group's critical line, as its outline marks it once expanded.
        Rectangle {
          visible: !root.single && root.entry.critical
          Layout.alignment: Qt.AlignVCenter
          implicitWidth: 8
          implicitHeight: 8
          radius: height / 2
          color: Theme.destructive
        }

        Text {
          visible: !root.single
          Layout.maximumWidth: content.width * 0.6
          text: root.entry.summary
          textFormat: Text.PlainText
          color: Theme.fg
          elide: Text.ElideRight
          font: Theme.heading
        }

        NotificationText {
          id: line

          Layout.fillWidth: true
          text: root.entry.body.replace(/\n/g, " ")
          // Eliding StyledText takes a line limit.
          maximumLineCount: root.single ? root.lines : 1
          onLinkOpened: Panels.close()
        }

        NotificationStamp {
          visible: !root.single
          entry: root.entry
          closable: root.closable
          onClosed: root.closed()
        }
      }

      RowLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: 12

        NotificationImage {
          id: image

          // A lone notification's image is the group's icon.
          visible: !root.single && root.entry.image !== ""
          Layout.alignment: Qt.AlignTop
          source: root.single ? "" : root.entry.image
          radius: Theme.buttonRadius
        }

        ColumnLayout {
          id: texts

          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          Layout.topMargin: image.visible ? Math.max(0, (image.height - implicitHeight) / 2) : 0
          spacing: 2

          RowLayout {
            id: summaryRow

            visible: !root.single
            Layout.fillWidth: true
            spacing: 8

            Text {
              id: summary

              Layout.fillWidth: true
              text: root.entry.summary
              textFormat: Text.PlainText
              color: Theme.fg
              wrapMode: Text.Wrap
              maximumLineCount: root.whole ? 6 : root.summaryLines
              elide: Text.ElideRight
              font: Theme.heading
            }

            NotificationStamp {
              Layout.alignment: Qt.AlignTop
              Layout.topMargin: 1
              entry: root.entry
              closable: true
              onClosed: swipe.slideAway(false, root.entry.dismissal())
            }

            // Overhanging the line, so the arrow costs it no height.
            Item {
              Layout.alignment: Qt.AlignTop
              visible: root.openable
              implicitWidth: 24
              implicitHeight: heading.height

              ExpanderArrow {
                anchors.centerIn: parent
                pointing: root.open ? "up" : "down"
              }
            }
          }

          // A lone notification's body is whole once its group expands; a card's opens as a popup does.
          NotificationText {
            id: body

            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            maximumLineCount: root.boxed && !root.whole ? root.bodyLines : 1000
            onLinkOpened: Panels.close()
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
        onInvoked: action => root.entry.invoke(action)
      }
    }
  }
}
