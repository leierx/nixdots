pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// One app's notifications in the center, newest first. Several fold into a
// stack: the newest card, with the edges of the others showing below it.
// Clicking the stack unfolds it, clicking its header folds it again, and
// Dismiss clears the lot.
ColumnLayout {
  id: root

  required property var entries
  property bool unfolded: false

  readonly property bool stacked: entries.length > 1
  // Edges of folded cards showing below the top one; the last one is taller
  // and says how many more there are.
  readonly property int sheets: Math.min(entries.length - 1, 2)
  readonly property int peek: Theme.px(8)
  readonly property int labelPeek: Theme.px(20)

  function sheetOffset(depth) {
    return depth < sheets ? depth * peek : (sheets - 1) * peek + labelPeek;
  }

  spacing: Theme.px(6)

  component TextButton: Text {
    id: button

    signal clicked()

    color: area.containsMouse ? Theme.fg : Theme.fgDim
    font {
      family: Theme.fontFamily
      pixelSize: Theme.fontSmall
    }

    MouseArea {
      id: area

      anchors.fill: parent
      anchors.margins: -Theme.px(4)
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  Item {
    visible: root.stacked
    Layout.fillWidth: true
    implicitHeight: Theme.px(22)

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.unfolded = !root.unfolded
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: Theme.px(4)
        rightMargin: Theme.px(4)
      }
      spacing: Theme.px(12)

      Text {
        Layout.fillWidth: true
        text: `${root.entries[0]?.notification.appName || "Notification"} · ${root.entries.length}`
        color: Theme.fgSoft
        elide: Text.ElideRight
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontSmall
          weight: Font.DemiBold
        }
      }

      TextButton {
        visible: root.unfolded
        text: "Fold"
        onClicked: root.unfolded = false
      }

      TextButton {
        text: "Dismiss"
        // Dismissing removes the entry, so walk a copy.
        onClicked: {
          for (const entry of root.entries.slice()) entry.notification.dismiss();
        }
      }
    }
  }

  // Folded: the newest card on top of the edges of the next two.
  Item {
    visible: root.stacked && !root.unfolded
    Layout.fillWidth: true
    implicitHeight: top.implicitHeight + root.sheetOffset(root.sheets)

    Repeater {
      model: root.sheets

      Rectangle {
        required property int index

        readonly property int depth: root.sheets - index

        x: Theme.px(10) * depth
        y: root.sheetOffset(depth)
        width: parent.width - x * 2
        height: top.implicitHeight
        radius: Theme.radius
        color: Theme.raised
        opacity: depth === 1 ? 1 : 0.6
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: top.implicitHeight + root.sheetOffset(root.sheets) - root.labelPeek + (root.labelPeek - height) / 2
      text: `+${root.entries.length - 1} more`
      color: Theme.fgDim
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontSmall
      }
    }

    NotificationCard {
      id: top

      width: parent.width
      entry: root.entries[0] ?? null
      flat: true
      folded: true
      onUnfold: root.unfolded = true
    }
  }

  // Unfolded, or a single notification.
  Repeater {
    model: ScriptModel {
      values: root.stacked && !root.unfolded ? [] : root.entries
    }

    NotificationCard {
      required property NotifEntry modelData

      Layout.fillWidth: true
      entry: modelData
      flat: true
    }
  }
}
