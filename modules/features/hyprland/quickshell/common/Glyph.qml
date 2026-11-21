import QtQuick
import QtQuick.Shapes

// A Symbols path: Material Design Icons draw in a 24 px box, scaled to the size asked.
Item {
  id: glyph

  required property string path
  property int size: 16
  property color color: Theme.fg

  implicitWidth: size
  implicitHeight: size

  Shape {
    width: 24
    height: 24
    scale: glyph.size / 24
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: glyph.color
      strokeColor: "transparent"
      fillRule: ShapePath.WindingFill

      PathSvg {
        path: glyph.path
      }
    }
  }
}
