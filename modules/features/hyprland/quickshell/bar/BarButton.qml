import QtQuick
import qs.common

Button {
  implicitHeight: 26
  // A pill, or a circle round an icon alone.
  radius: height / 2
  padding: text === "" ? 4 : 12
  flat: true
  font: Theme.caption
}
