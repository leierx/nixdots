pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

ColumnLayout {
  id: root

  readonly property var locale: Qt.locale()
  readonly property date today: Time.now
  property date month: new Date(today.getFullYear(), today.getMonth(), 1)
  readonly property bool away: month.getFullYear() !== today.getFullYear() || month.getMonth() !== today.getMonth()

  readonly property var weeks: {
    const lead = (month.getDay() - locale.firstDayOfWeek + 7) % 7;
    return Array.from({ length: 6 }, (_, week) => Array.from({ length: 7 }, (_, day) => new Date(month.getFullYear(), month.getMonth(), 1 - lead + week * 7 + day)));
  }

  // GNOME Shell's day button, 3em of its smaller font, and its 2 px margins.
  readonly property int cell: Math.round(2.5 * Theme.em) + 4

  spacing: 4

  function shift(months) {
    month = new Date(month.getFullYear(), month.getMonth() + months, 1);
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  // ISO 8601: weeks start on Monday, and week 1 holds the year's first Thursday.
  function isoWeek(day) {
    const thursday = new Date(Date.UTC(day.getFullYear(), day.getMonth(), day.getDate() + 3 - (day.getDay() + 6) % 7));
    const firstThursday = new Date(Date.UTC(thursday.getUTCFullYear(), 0, 4));
    return 1 + Math.round(((thursday - firstThursday) / 86400000 - 3 + (firstThursday.getUTCDay() + 6) % 7) / 7);
  }

  component Arrow: IconButton {
    implicitWidth: root.cell
    implicitHeight: root.cell
    flat: true
    expander: true
  }

  // qmllint disable Quick.layout-positioning
  component Cell: Text {
    width: root.cell
    height: root.cell
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
  // qmllint enable Quick.layout-positioning

  ColumnLayout {
    Layout.leftMargin: 8
    Layout.bottomMargin: 8
    spacing: 0

    Text {
      text: root.locale.toString(root.today, "dddd")
      color: Theme.fgDim
      font: Theme.heading
    }

    Text {
      text: root.locale.toString(root.today, "d MMMM yyyy")
      color: Theme.fg
      font: Theme.title2

      MouseArea {
        anchors.fill: parent
        enabled: root.away
        // Disabled, it would still set a hand.
        cursorShape: root.away ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.month = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true

    Arrow {
      pointing: "left"
      tooltip: "Previous Month"
      onClicked: root.shift(-1)
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.locale.toString(root.month, root.month.getFullYear() === root.today.getFullYear() ? "MMMM" : "MMMM yyyy")
      color: Theme.fg
      font: Theme.heading
    }

    Arrow {
      pointing: "right"
      tooltip: "Next Month"
      onClicked: root.shift(1)
    }
  }

  Column {
    spacing: 2

    Row {
      Item {
        width: root.cell
        height: root.cell
      }

      Repeater {
        model: 7

        Cell {
          required property int index

          text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.NarrowFormat)
          color: Theme.fgDim
          font: Theme.captionHeading
        }
      }
    }

    Repeater {
      model: root.weeks

      Row {
        id: week

        required property var modelData

        Cell {
          // The week of the row's Monday, wherever the locale starts it.
          text: root.isoWeek(week.modelData[(8 - root.locale.firstDayOfWeek) % 7])
          color: Theme.fgDim
          font: Theme.caption
        }

        Repeater {
          model: week.modelData

          Item {
            id: day

            required property date modelData
            readonly property bool isToday: root.sameDay(modelData, root.today)

            width: root.cell
            height: root.cell

            Rectangle {
              anchors.fill: parent
              anchors.margins: 2
              radius: width / 2
              color: Theme.accentBg
              visible: day.isToday
            }

            Cell {
              text: day.modelData.getDate()
              color: day.isToday ? Theme.accentFg : day.modelData.getMonth() === root.month.getMonth() ? Theme.fg : Theme.fgDim
              font: day.isToday ? Theme.heading : Theme.body
            }
          }
        }
      }
    }
  }

  WheelSteps {
    id: notches
  }

  WheelHandler {
    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      const months = notches.steps(event);
      if (months !== 0) root.shift(-months);
    }
  }
}
