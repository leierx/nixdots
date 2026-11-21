pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.nix

Item {
  id: root

  required property NotifEntry entry

  property bool expanded: false
  // Shown whole until a collapse has eased the card down, so collapsing animates as expanding does.
  property bool full: false
  readonly property bool expandable: expanded || full || summary.truncated || body.truncated
  readonly property int summaryLines: 2
  readonly property int bodyLines: 4
  // What the text loses on collapsing, worked out from its lines while it is still whole.
  readonly property real excess: {
    if (expanded || !full) return 0;
    const cut = (text, lines) => text.lineCount > lines ? text.implicitHeight * (1 - lines / text.lineCount) : 0;
    return cut(summary, summaryLines) + cut(body, bodyLines);
  }

  onExpandedChanged: {
    fold.stop();
    if (expanded) full = true;
    else fold.start();
  }

  implicitHeight: card.height

  Timer {
    id: fold

    interval: 200
    onTriggered: root.full = false
  }

  SwipeArea {
    id: swipe

    anchors.fill: parent
    target: card
    rightOnly: true
    // A hand where the click expands or opens, as in the center; an arrow where it only puts the popup away.
    restCursor: root.expandable || root.entry.defaultAction || root.entry.buttons.length === 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
    onSwiped: left => {
      if (!left) swipe.slideAway(false, root.entry.dismissal());
    }
    onTapped: {
      if (root.expandable) root.expanded = !root.expanded;
      else if (root.entry.defaultAction) root.entry.invoke(root.entry.defaultAction);
      else if (root.entry.buttons.length === 1) root.entry.invoke(root.entry.buttons[0]);
      else root.entry.popup = false;
    }
  }

  FontMetrics {
    id: line

    font: Theme.heading
  }

  Card {
    id: card

    width: root.width
    height: content.implicitHeight + 2 * Theme.padding - root.excess
    radius: Theme.messageRadius
    color: Theme.messageBg
    border.color: root.entry.critical ? Theme.destructive : Theme.popoverBorder
    shadow.spreadBy: 2
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

        // Shell's banner header: the app, the age, then expand and close.
        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.basePadding

          IconImage {
            id: appIcon

            // One that is no picture leaves the name alone, as the body's icon gives way to the initial.
            visible: root.entry.appIcon !== "" && appIcon.status === Image.Ready
            implicitSize: 16
            source: root.entry.appIcon
          }

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

          ExpanderArrow {
            visible: root.expandable
            pointing: root.expanded ? "up" : "down"
            color: Theme.fgDim
          }

          IconButton {
            objectName: "popup:close"
            small: true
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
            id: texts

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Math.max(0, (icon.height - implicitHeight) / 2)
            spacing: 2

            RowLayout {
              id: summaryRow

              Layout.fillWidth: true
              visible: summary.text !== ""
              spacing: 6

              Text {
                id: summary

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                text: root.entry.summary
                textFormat: Text.PlainText
                color: Theme.fg
                wrapMode: Text.Wrap
                maximumLineCount: root.full ? 6 : root.summaryLines
                elide: Text.ElideRight
                font: Theme.heading
              }

            }

            // Expanded, still short enough that a popup always fits on the screen.
            NotificationText {
              id: body

              Layout.fillWidth: true
              visible: text !== ""
              text: root.entry.body
              maximumLineCount: root.full ? 15 : root.bodyLines
              onLinkOpened: root.entry.popup = false
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: root.entry.progress !== undefined
          implicitHeight: 4
          radius: height / 2
          color: Theme.troughBg

          Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.entry.progress ?? 0)) / 100
            height: parent.height
            radius: parent.radius
            color: Theme.accentBg
          }
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
