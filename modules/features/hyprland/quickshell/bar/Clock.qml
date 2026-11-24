import QtQuick
import qs.common

BarButton {
  required property string screenName

  checked: Panels.active === `center:${screenName}`
  text: Qt.locale().toString(Time.now, "ddd d MMMM ‧ HH:mm")
  tooltip: "Notifications and Calendar"
  font: Theme.numericSemiBold
  onClicked: Panels.toggle(`center:${screenName}`)
}
