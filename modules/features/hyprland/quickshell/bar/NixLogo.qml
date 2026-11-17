import QtQuick
import qs.common

Item {
  implicitWidth: 31
  implicitHeight: 26

  Image {
    anchors.centerIn: parent
    source: "../common/nixos.svg"
    sourceSize.width: 22
    sourceSize.height: 22
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Panels.toggle("power")
  }
}
