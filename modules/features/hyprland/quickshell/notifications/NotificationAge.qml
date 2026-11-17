import QtQuick
import qs.common

Text {
  required property NotifEntry entry

  text: entry ? Notifs.age(entry.time) : ""
  color: Theme.fgDim
  font: Theme.caption
}
