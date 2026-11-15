pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// A month at a time under today's date, weeks starting on the locale's first
// day, with ISO week numbers down the side. The arrows or the wheel change the
// month; clicking the date goes back to today's.
ColumnLayout {
  id: root

  readonly property var locale: Qt.locale()
  readonly property date today: clock.date
  // The first of the month shown.
  property date month: new Date(today.getFullYear(), today.getMonth(), 1)

  // The six weeks shown, from the first day of the week holding the 1st.
  readonly property var days: {
    const lead = (month.getDay() - locale.firstDayOfWeek + 7) % 7;
    return Array.from({ length: 42 }, (_, i) => new Date(month.getFullYear(), month.getMonth(), 1 - lead + i));
  }

  readonly property int cell: Theme.px(36)

  spacing: Theme.px(4)

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

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  component Arrow: Rectangle {
    id: arrow

    property alias text: label.text

    signal clicked()

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: width / 2
    color: area.containsMouse ? Theme.selected : "transparent"

    Text {
      id: label

      anchors.centerIn: parent
      color: Theme.fg
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontLarge
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: arrow.clicked()
    }
  }

  ColumnLayout {
    Layout.leftMargin: Theme.px(8)
    Layout.bottomMargin: Theme.px(8)
    spacing: 0

    Text {
      text: root.locale.toString(root.today, "dddd")
      color: Theme.fgDim
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontBody
        weight: Font.DemiBold
      }
    }

    Text {
      text: root.locale.toString(root.today, "d MMMM yyyy")
      color: Theme.fg
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontLarge
        weight: Font.Bold
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.month = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true

    Arrow {
      text: "‹"
      onClicked: root.shift(-1)
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.locale.toString(root.month, root.month.getFullYear() === root.today.getFullYear() ? "MMMM" : "MMMM yyyy")
      color: Theme.fg
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontBody
        weight: Font.DemiBold
      }
    }

    Arrow {
      text: "›"
      onClicked: root.shift(1)
    }
  }

  Grid {
    columns: 8
    rowSpacing: Theme.px(2)

    // The corner above the week numbers.
    Item {
      width: root.cell
      height: root.cell
    }

    Repeater {
      model: 7

      Text {
        required property int index

        width: root.cell
        height: root.cell
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.NarrowFormat)
        color: Theme.fgDim
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontSmall
          weight: Font.DemiBold
        }
      }
    }

    Repeater {
      model: 48

      Item {
        id: cell

        required property int index

        readonly property bool isWeek: index % 8 === 0
        readonly property date day: root.days[index - Math.floor(index / 8) - 1] ?? new Date()
        readonly property bool inMonth: day.getMonth() === root.month.getMonth()
        readonly property bool isToday: !isWeek && root.sameDay(day, root.today)

        width: root.cell
        height: root.cell

        Rectangle {
          anchors.centerIn: parent
          width: cell.isWeek ? Theme.px(26) : parent.width
          height: cell.isWeek ? Theme.px(22) : parent.height
          radius: cell.isWeek ? Theme.px(6) : width / 2
          color: cell.isWeek ? Theme.raised : cell.isToday ? Theme.accent : dayArea.containsMouse ? Theme.selected : "transparent"
        }

        Text {
          anchors.centerIn: parent
          // The week of the row's Monday, wherever the locale starts it.
          text: cell.isWeek ? root.isoWeek(root.days[index - Math.floor(index / 8) + (8 - root.locale.firstDayOfWeek) % 7]) : cell.day.getDate()
          color: cell.isWeek || !cell.inMonth ? Theme.fgDim : Theme.fg
          font {
            family: Theme.fontFamily
            pixelSize: cell.isWeek ? Theme.fontSmall : Theme.fontBody
            weight: cell.isToday ? Font.Bold : Font.Normal
          }
        }

        MouseArea {
          id: dayArea

          anchors.fill: parent
          enabled: !cell.isWeek
          hoverEnabled: true
        }
      }
    }
  }

  // A notch a month; touchpads add up to one.
  WheelHandler {
    property real pending: 0

    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      pending += event.angleDelta.y;
      const months = Math.trunc(pending / 120);
      pending -= months * 120;
      if (months !== 0) root.shift(-months);
    }
  }
}
