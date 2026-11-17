import QtQuick
import qs.common

Button {
  implicitHeight: 27
  radius: height / 2
  padding: 12
  flat: true
  checked: Panels.active === "center"
  text: Qt.locale().toString(Time.now, "ddd dd MMMM ‧ HH:mm")
  // BarText's lettering.
  font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: Font.Medium })
  onClicked: Panels.toggle("center")
}
