import QtQuick
import QtQuick.Shapes

// The NixOS snowflake in its two blues, a square as tall as the bar. It does
// nothing yet, so it has no hover or press state.
Item {
  implicitWidth: implicitHeight
  implicitHeight: 34

  // Papirus' distributor-logo-nixos, its lambdas in a 56×48 box.
  Shape {
    anchors.centerIn: parent
    width: 56
    height: 48
    scale: 18 / 48
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "#5277c3"
      strokeColor: "transparent"

      PathSvg {
        path: "M 16.453 24 L 12.99 30 L 17.031 37 L 12.332 45.139 L 14 48 H 17.607 L 20.494 42.998 L 23.383 48 H 30.309 Z M 47.73 9.824 L 33.773 34 H 40.701 L 44.742 27 H 54.25 L 56 24 L 54.25 21 H 48.207 L 51.213 15.793 Z M 14 0 L 12.332 2.861 L 15.299 8 H 9.334 L 5.834 14 H 33.773 L 30.309 8 H 22.227 L 17.607 0 Z"
      }
    }

    ShapePath {
      fillColor: "#7ebae4"
      strokeColor: "transparent"

      PathSvg {
        path: "M 25.691 0 L 39.547 24 L 43.01 18 L 38.969 11 L 43.668 2.861 L 42 0 H 38.393 L 35.506 5.002 L 32.617 0 Z M 15.299 14 L 11.258 21 H 1.75 L 0 24 L 1.75 27 H 7.793 L 4.787 32.207 L 8.27 38.176 L 22.227 14 Z M 22.227 34 L 25.691 40 H 33.773 L 38.393 48 H 42 L 43.668 45.139 L 40.701 40 H 46.666 L 50.166 34 Z"
      }
    }
  }
}
