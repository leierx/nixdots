import QtQuick
import QtQuick.Shapes

// Material Symbols draw in a 960 px box above the origin.
Item {
  id: glyph

  required property string path
  property int size: 20
  property color color: Theme.fg

  implicitWidth: size
  implicitHeight: size

  Shape {
    y: glyph.size
    width: 960
    height: 960
    scale: glyph.size / 960
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
