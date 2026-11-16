import QtQuick
import Quickshell
import qs.common

// The date and time, "Mon 16 November ‧ 17:04"; a click opens the
// notification center.
MouseArea {
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: Panels.toggle("center")

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  Text {
    id: label

    text: Qt.locale().toString(clock.date, "ddd dd MMMM ‧ HH:mm")
    color: Theme.fg
    font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: Font.Medium })
  }
}
