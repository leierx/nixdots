import QtQuick
import qs.common

BarButton {
  checked: Panels.active === "center"
  text: Qt.locale().toString(Time.now, "ddd dd MMMM ‧ HH:mm")
  onClicked: Panels.toggle("center")
}
