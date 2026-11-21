import QtQuick
import QtQuick.Shapes

// Adwaita's symbolic icons draw in a 16 px box; what follows a path's "|" is its faint part, at Adwaita's 35 %.
Item {
  id: glyph

  required property string path
  property int size: 16
  property color color: Theme.fg
  readonly property var parts: path.split("|")

  implicitWidth: size
  implicitHeight: size

  component Part: Shape {
    id: part

    property string drawn: ""
    property int size: 16
    property color color: Theme.fg

    width: 16
    height: 16
    scale: part.size / 16
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: part.color
      strokeColor: "transparent"
      fillRule: ShapePath.WindingFill

      PathSvg {
        path: part.drawn
      }
    }
  }

  Part {
    drawn: glyph.parts[0]
    size: glyph.size
    color: glyph.color
  }

  Part {
    visible: drawn !== ""
    opacity: 0.35
    drawn: glyph.parts[1] ?? ""
    size: glyph.size
    color: glyph.color
  }
}
