import QtQuick

// libadwaita's .keycap: the foreground at 10 % over a 2 px shade along its foot.
Rectangle {
  id: root

  property alias text: label.text

  implicitWidth: Math.max(implicitHeight, label.implicitWidth + 12)
  implicitHeight: 26
  radius: Theme.keycapRadius
  color: Theme.keycapBg
  clip: true

  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 2
    color: Theme.keycapShade
  }

  Text {
    id: label

    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    color: Theme.fg
    font: Theme.caption
  }
}
