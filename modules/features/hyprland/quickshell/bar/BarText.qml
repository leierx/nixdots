import QtQuick
import qs.common

// The old waybar's 12pt lettering.
Text {
  property int weight: Font.Medium

  color: Theme.fg
  font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: weight })
}
