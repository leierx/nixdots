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
  readonly property bool picture: image !== ""
  // An app icon sent without an image is Quickshell's image too, which a badge would only repeat.
  readonly property bool badged: picture && appIcon !== "" && appIcon !== image

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    anchors.fill: parent
    visible: !root.picture
    radius: root.radius
    color: root.entry?.critical ? Theme.destructiveBg : Theme.card
  }

  IconImage {
    anchors.centerIn: parent
    visible: !root.picture && root.appIcon !== ""
    source: root.picture ? "" : root.appIcon
    implicitSize: Math.round(root.size * 0.7)
  }

  Text {
    anchors.centerIn: parent
    visible: !root.picture && root.appIcon === ""
    text: (root.entry?.notification.appName || "?")[0].toUpperCase()
    color: Theme.fg
    font: Theme.heading
  }

  NotificationImage {
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
