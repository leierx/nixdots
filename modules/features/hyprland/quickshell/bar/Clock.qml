import QtQuick
import Quickshell
import qs.common

// The date and time, "Mon 16 November ‧ 17:04"; a click opens the
// notification center.
Rectangle {
  id: root

  implicitWidth: label.implicitWidth + 24
  implicitHeight: 22
  radius: 6
  color: Panels.active === "center" ? Theme.selected : area.containsMouse ? Theme.hover : "transparent"

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: Qt.locale().toString(clock.date, "ddd dd MMMM ‧ HH:mm")
    color: Theme.fg
    font.family: Theme.body.family
    font.pointSize: Theme.body.pointSize
    font.weight: Font.Medium
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Panels.toggle("center")
  }
}
