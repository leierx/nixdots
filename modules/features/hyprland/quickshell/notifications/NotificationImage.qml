import QtQuick
import Quickshell.Widgets

ClippingRectangle {
  id: root

  property alias source: image.source
  readonly property alias status: image.status
  property int size: 40

  implicitWidth: size
  implicitHeight: size
  color: "transparent"

  Image {
    id: image

    anchors.fill: parent
    sourceSize {
      width: root.size * 2
      height: root.size * 2
    }
    fillMode: Image.PreserveAspectCrop
    // The image provider reuses URLs for different notifications.
    cache: false
  }
}
