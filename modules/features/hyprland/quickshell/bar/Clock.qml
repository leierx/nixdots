import QtQuick
import Quickshell
import qs.common

MouseArea {
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: Panels.toggle("center")

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  BarText {
    id: label

    text: Qt.locale().toString(clock.date, "ddd dd MMMM ‧ HH:mm")
  }
}
