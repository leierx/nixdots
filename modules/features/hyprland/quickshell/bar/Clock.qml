import QtQuick
import qs.common
import qs.notifications

BarButton {
  required property string screenName

  checked: Panels.active === `center:${screenName}`
  text: Qt.locale().toString(Time.now, "ddd d MMMM ‧ HH:mm")
  tooltip: "Notifications and Calendar"
  font: Theme.numericSemiBold
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: button => {
    if (button === Qt.RightButton) Notifs.dnd = !Notifs.dnd;
    else Panels.toggle(`center:${screenName}`);
  }
}
