pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
  id: root

  readonly property var now: Weather.now
  readonly property var next: Weather.hours.slice(1, 7)
  // The next day's rather than the rest of today's, which late in the evening is an hour or two.
  readonly property var day: Weather.hours.slice(0, 24).map(hour => hour.temperature)
  readonly property int padding: Theme.padding

  implicitHeight: content.implicitHeight + 2 * padding
  radius: Theme.cardRadius
  color: Theme.cardBg

  ColumnLayout {
    id: content

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: root.padding
    }
    spacing: 16

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Glyph {
        path: root.now?.icon ?? ""
        size: 64
      }

      ColumnLayout {
        spacing: -6

        Text {
          text: Weather.place
          color: Theme.fg
          font: Theme.heading
        }

        Row {
          Text {
            text: Math.round(root.now?.temperature ?? 0)
            color: Theme.fg
            font: Theme.largeTitle
          }

          Text {
            topPadding: 10
            text: "°C"
            color: Theme.fgDim
            font: Theme.heading
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom
        Layout.bottomMargin: 6
        spacing: 2

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          text: Weather.describe(root.now?.symbol ?? "")
          color: Theme.fg
          font: Theme.heading
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          visible: root.day.length > 0
          text: `${Weather.degrees(Math.max(...root.day))} / ${Weather.degrees(Math.min(...root.day))}`
          color: Theme.fgDim
          font: Theme.body
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Repeater {
        model: root.next

        ColumnLayout {
          id: hour

          required property var modelData

          Layout.fillWidth: true
          Layout.preferredWidth: 1
          spacing: 4

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.locale().toString(hour.modelData.time, "HH")
            color: Theme.fgDim
            font: Theme.caption
          }

          Glyph {
            Layout.alignment: Qt.AlignHCenter
            path: hour.modelData.icon
            size: 32
          }

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Weather.degrees(hour.modelData.temperature)
            color: Theme.fg
            font: Theme.body
          }
        }
      }
    }
  }
}
