import QtQuick
import Quickshell.Widgets

ClippingRectangle {
  id: root

  property alias source: image.source
  property int size: 40
  // The notification it shows the picture of, to keep a copy of one only the server holds.
  property NotifEntry entry: null

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
    onStatusChanged: if (status === Image.Ready) root.entry?.keep("image", image)
  }
}
