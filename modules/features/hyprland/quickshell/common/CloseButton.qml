import QtQuick
import QtQuick.Shapes

// GNOME's notifications close from a round flat button with Adwaita's window-close-symbolic.
Button {
  implicitWidth: 24
  implicitHeight: 24
  radius: height / 2
  flat: true

  Shape {
    anchors.centerIn: parent
    width: 16
    height: 16
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: Theme.fg
      strokeWidth: 1.5
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap

      PathMove {
        x: 4.5
        y: 4.5
      }
      PathLine {
        x: 11.5
        y: 11.5
      }
      PathMove {
        x: 11.5
        y: 4.5
      }
      PathLine {
        x: 4.5
        y: 11.5
      }
    }
  }
}
