import QtQuick
import Quickshell
import qs.common

// A flat button, as GNOME's panel draws its date: no background until the pointer is on it, and held while the center is open.
MouseArea {
  id: root

  implicitWidth: label.implicitWidth + 24
  implicitHeight: 27
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor
  onClicked: Panels.toggle("center")

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.pressed || Panels.active === "center" ? Theme.buttonHover : root.containsMouse ? Theme.button : "transparent"
  }

  BarText {
    id: label

    anchors.centerIn: parent
    text: Qt.locale().toString(clock.date, "ddd dd MMMM ‧ HH:mm")
  }
}
