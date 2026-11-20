import QtQuick

// Played through rather than held while pressed: after a switch the release may not come until the pointer moves.
SequentialAnimation {
  id: root

  required property Item target

  NumberAnimation {
    target: root.target
    property: "scale"
    to: 0.85
    duration: Theme.tap
    easing.type: Easing.OutQuad
  }

  NumberAnimation {
    target: root.target
    property: "scale"
    to: 1
    duration: Theme.move
    easing.type: Easing.OutBack
  }
}
