import QtQuick

// The NixOS logo, as tall as the bar's buttons. It does nothing yet, so it
// has no hover or press state.
Item {
  implicitWidth: 31
  implicitHeight: 26

  Image {
    anchors.centerIn: parent
    source: "nixos.svg"
    sourceSize.width: 22
    sourceSize.height: 22
  }
}
