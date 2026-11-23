import QtQuick
import Quickshell
import qs.common

BarButton {
  required property ShellScreen screen

  checked: Panels.active === "center"
  text: Qt.locale().toString(Time.now, "ddd dd MMMM ‧ HH:mm")
  tooltip: "Notifications and Calendar"
  font: Theme.numericSemiBold
  onClicked: Panels.toggle("center", screen?.name ?? "")
}
