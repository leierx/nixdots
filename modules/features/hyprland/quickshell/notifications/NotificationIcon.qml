import QtQuick
import Quickshell.Widgets
import qs.common

Item {
  id: root

  required property NotifEntry entry
  property string image: entry?.image ?? ""
  property int size: 40
  property real radius: size / 2

  readonly property string appIcon: entry?.appIcon ?? ""
  // One that fails to load (an app naming a file that is no picture) gives way to what comes after it.
  readonly property bool picture: image !== "" && pictureView.status !== Image.Error
  readonly property bool icon: appIcon !== "" && iconView.status !== Image.Error
  // An app icon sent without an image is Quickshell's image too, which a badge would only repeat.
  readonly property bool badged: picture && icon && appIcon !== image

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    anchors.fill: parent
    visible: !root.picture
    radius: root.radius
    color: root.entry?.critical ? Theme.destructiveBg : Theme.card
  }

  IconImage {
    id: iconView

    anchors.centerIn: parent
    visible: !root.picture && root.icon
    source: root.appIcon
    implicitSize: Math.round(root.size * 0.7)
  }

  Text {
    anchors.centerIn: parent
    visible: !root.picture && !root.icon
    text: (root.entry?.notification.appName || "?")[0].toUpperCase()
    color: Theme.fg
    font: Theme.heading
  }

  NotificationImage {
    id: pictureView

    anchors.fill: parent
    visible: root.picture
    source: root.image
    size: root.size
    radius: root.radius
  }

  IconImage {
    anchors {
      right: parent.right
      bottom: parent.bottom
      margins: -3
    }
    visible: root.badged
    source: root.badged ? root.appIcon : ""
    implicitSize: Math.round(root.size / 2)
  }
}
