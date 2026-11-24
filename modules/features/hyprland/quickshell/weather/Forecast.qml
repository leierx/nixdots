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

  // MET's SVGs drawn at the size shown, so they stay sharp.
  component WeatherIcon: Image {
    property int size: 32

    width: size
    height: size
    sourceSize: Qt.size(size, size)
    fillMode: Image.PreserveAspectFit
  }

  readonly property var sky: Theme.skies[Weather.sky(root.now?.symbol ?? "")] ?? Theme.skies.cloud

  implicitHeight: content.implicitHeight + 2 * padding
  radius: Theme.cardRadius
  color: "transparent"
  // The sky it forecasts, as the user asked for colour here.
  gradient: Gradient {
    GradientStop {
      position: 0
      color: root.sky[0]
    }
    GradientStop {
      position: 1
      color: root.sky[1]
    }
  }

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

      WeatherIcon {
        size: 76
        source: root.now?.icon ?? ""
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
            color: Theme.fgStrong
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
          color: Theme.fgStrong
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
            textFormat: Text.PlainText
            color: Theme.fgStrong
            font: Theme.caption
          }

          WeatherIcon {
            Layout.alignment: Qt.AlignHCenter
            size: 30
            source: hour.modelData.icon
          }

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Weather.degrees(hour.modelData.temperature)
            textFormat: Text.PlainText
            color: Theme.fg
            font: Theme.body
          }
        }
      }
    }
  }
}
