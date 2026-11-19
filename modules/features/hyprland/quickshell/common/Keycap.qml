import QtQuick

Rectangle {
  id: root

  property alias text: label.text

  implicitWidth: Math.max(implicitHeight, label.implicitWidth + 14)
  implicitHeight: 24
  radius: Theme.smallRadius
  color: Theme.button

  Text {
    id: label

    anchors.centerIn: parent
    color: Theme.fg
    font: Theme.caption
  }
}
