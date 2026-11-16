import QtQuick
import QtQuick.Shapes
import qs.common

Row {
  id: root

  readonly property color level: Power.plugged ? Theme.success : Power.critical ? Theme.destructive : Power.low ? Theme.warning : Theme.fg

  visible: Power.present
  spacing: 6
  leftPadding: 8
  rightPadding: 8

  Item {
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    height: 12

    Rectangle {
      id: body

      width: 22
      height: parent.height
      radius: 3.5
      color: "transparent"
      border.width: 1.5
      border.color: Theme.fgDim

      Rectangle {
        x: 2.5
        y: 2.5
        width: (parent.width - 5) * Math.max(0, Math.min(Power.percent, 100)) / 100
        height: parent.height - 5
        radius: 1.5
        color: root.level
      }
    }

    Rectangle {
      anchors.left: body.right
      anchors.leftMargin: 0.5
      anchors.verticalCenter: body.verticalCenter
      width: 1.5
      height: 5
      radius: 1
      color: Theme.fgDim
    }
  }

  Shape {
    anchors.verticalCenter: parent.verticalCenter
    width: 7
    height: 11
    visible: Power.plugged
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.level
      strokeColor: "transparent"

      PathSvg {
        path: "M 4.5 0 L 0 6.2 L 3 6.2 L 2.5 11 L 7 4.8 L 4 4.8 Z"
      }
    }
  }

  BarText {
    anchors.verticalCenter: parent.verticalCenter
    text: `${Power.percent}%`
    color: Power.low ? root.level : Theme.fg
  }
}
