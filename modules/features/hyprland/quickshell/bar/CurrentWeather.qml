import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.weather

// The weather this hour, an icon and the temperature; hidden until known.
Row {
  visible: Weather.now !== null
  spacing: 6

  IconImage {
    anchors.verticalCenter: parent.verticalCenter
    implicitSize: 18
    source: Quickshell.iconPath(Weather.now?.icon ?? "", "weather-none-available")
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: `${Math.round(Weather.now?.temperature ?? 0)}°`
    color: Theme.fg
    font: Theme.body
  }
}
