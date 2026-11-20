import QtQuick

// libadwaita's switch.
Rectangle {
  id: toggle

  property bool checked: false

  signal clicked()

  implicitWidth: 46
  implicitHeight: 26
  radius: height / 2
  color: checked ? Theme.accentBg : Theme.trough

  Behavior on color {
    ColorAnimation {
      duration: Theme.fade
    }
  }

  Rectangle {
    x: toggle.checked ? toggle.width - width - 3 : 3
    anchors.verticalCenter: parent.verticalCenter
    width: 20
    height: 20
    radius: width / 2
    color: toggle.checked || area.containsMouse ? Theme.fg : Theme.slider

    Behavior on x {
      NumberAnimation {
        duration: 200
        easing.type: Easing.OutCubic
      }
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    enabled: toggle.enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: toggle.clicked()
  }
}
