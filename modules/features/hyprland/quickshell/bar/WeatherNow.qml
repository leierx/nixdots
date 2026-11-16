import QtQuick
import qs.common
import qs.weather

// The forecast is in the center, so a click opens it.
MouseArea {
  visible: Weather.now !== null
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: Panels.toggle("center")

  Row {
    id: row

    spacing: 6
    leftPadding: 8
    rightPadding: 8

    Image {
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      sourceSize: Qt.size(width, height)
      source: Weather.now?.icon ?? ""
    }

    BarText {
      anchors.verticalCenter: parent.verticalCenter
      text: Weather.degrees(Weather.now?.temperature ?? 0)
    }
  }
}
