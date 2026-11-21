import QtQuick
import qs.common

BarButton {
  // A third of a turn, after which its two blues are where they were, once each time the pointer arrives; one under way finishes.
  onHoveredChanged: if (hovered && !spin.running) spin.start()
  tooltip: "Power Menu"
  onClicked: Panels.toggle("power")

  Image {
    anchors.centerIn: parent
    source: "../common/nixos.svg"
    sourceSize.width: 20
    sourceSize.height: 20
    // Turns by its centre, the snowflake's, rather than the image's corner.
    transformOrigin: Item.Center
    antialiasing: true

    RotationAnimation on rotation {
      id: spin

      running: false
      from: 0
      to: 120
      duration: Theme.settle
      easing.type: Easing.InOutCubic
    }
  }
}
