pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
  id: root

  readonly property var now: Weather.now
  readonly property var days: Weather.periods
    .map(period => new Date(period.start.getFullYear(), period.start.getMonth(), period.start.getDate()))
    .filter((date, index, dates) => dates.findIndex(other => other.getTime() === date.getTime()) === index)
    .slice(0, 3)
  readonly property int labelWidth: 66
  readonly property int padding: 16

  // MET's SVGs drawn at the size shown, so they stay sharp.
  component WeatherIcon: Image {
    property int size: 32

    width: size
    height: size
    sourceSize: Qt.size(size, size)
    fillMode: Image.PreserveAspectFit
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  implicitHeight: content.implicitHeight + 2 * padding
  radius: Theme.cardRadius
  color: Theme.card

  ColumnLayout {
    id: content

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: root.padding
    }
    spacing: 12

    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      WeatherIcon {
        size: 52
        source: root.now?.icon ?? ""
      }

      Text {
        text: Weather.degrees(root.now?.temperature ?? 0)
        color: Theme.fg
        font.family: Theme.body.family
        font.pointSize: 22
        font.weight: Font.Light
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          Layout.fillWidth: true
          text: Weather.describe(root.now?.symbol ?? "")
          color: Theme.fg
          font: Theme.heading
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: [Weather.place, `${Math.round(root.now?.wind ?? 0)} m/s`, Weather.millimetres(root.now?.rain ?? 0)].filter(part => part).join(" · ")
          color: Theme.fgDim
          font: Theme.caption
          elide: Text.ElideRight
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Item {
          Layout.preferredWidth: root.labelWidth
        }

        Repeater {
          model: ["Night", "Morning", "Afternoon", "Evening"]

          Text {
            required property string modelData

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: Theme.fgDim
            font: Theme.caption
          }
        }
      }

      Repeater {
        model: root.days

        RowLayout {
          id: day

          required property date modelData
          required property int index

          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.preferredWidth: root.labelWidth
            text: ["Today", "Tomorrow"][day.index] ?? Qt.locale().toString(day.modelData, "ddd")
            color: Theme.fg
            font: Theme.body
          }

          Repeater {
            // A quarter already over has no forecast.
            model: [0, 1, 2, 3].map(quarter => Weather.periods.find(period => period.quarter === quarter && root.sameDay(period.start, day.modelData)) ?? null)

            ColumnLayout {
              id: cell

              required property var modelData

              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: 1

              Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 28
                implicitHeight: 28

                WeatherIcon {
                  anchors.fill: parent
                  visible: cell.modelData !== null
                  size: 28
                  source: cell.modelData?.icon ?? ""
                }

                Text {
                  anchors.centerIn: parent
                  visible: cell.modelData === null
                  text: "–"
                  color: Theme.fgDim
                  font: Theme.body
                }
              }

              Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                // Nights by their low, the rest by their high.
                text: cell.modelData ? Weather.degrees(cell.modelData.quarter === 0 ? cell.modelData.low : cell.modelData.high) : " "
                color: Theme.fg
                font: Theme.caption
              }
            }
          }
        }
      }
    }
  }
}
