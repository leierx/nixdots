import QtQuick
import qs.common

Item {
  id: root

  implicitWidth: 30
  implicitHeight: 26

  Image {
    id: logo

    anchors.centerIn: parent
    source: "../common/nixos.svg"
    sourceSize.width: 20
    sourceSize.height: 20
    // Turns by its centre, the snowflake's, rather than the image's corner.
    transformOrigin: Item.Center
    antialiasing: true

    // A third of a turn, after which its two blues are where they were, once each time the pointer arrives; one under way finishes.
    RotationAnimation on rotation {
      id: spin

      running: false
      from: 0
      to: 120
      duration: 600
      easing.type: Easing.InOutCubic
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: if (!spin.running) spin.start()
    onClicked: Panels.toggle("power")
  }
}
