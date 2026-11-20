import QtQuick
import QtQuick.Shapes

Shape {
  id: root

  property string pointing: "down"

  // Shape sizes itself to the path otherwise.
  width: 16
  height: 16
  preferredRendererType: Shape.CurveRenderer
  rotation: ({ down: 0, left: 90, up: 180, right: -90 })[pointing] ?? 0

  Behavior on rotation {
    NumberAnimation {
      duration: Theme.move
      easing.type: Easing.OutCubic
    }
  }

  ShapePath {
    fillColor: Theme.fg
    strokeColor: "transparent"

    // Raised a pixel so it sits centred in its 16 px.
    PathSvg {
      path: "m 3.292969 6.707031 l 4 4 c 0.390625 0.390625 1.023437 0.390625 1.414062 0 l 4 -4 c 0.390625 -0.390625 0.390625 -1.023437 0 -1.414062 s -1.023437 -0.390625 -1.414062 0 l -3.292969 3.292969 l -3.292969 -3.292969 c -0.390625 -0.390625 -1.023437 -0.390625 -1.414062 0 s -0.390625 1.023437 0 1.414062 z"
    }
  }
}
