pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// Past a handful of outputs, or once they are too small to tell apart, a count says more than a drawing.
Item {
  id: root

  required property var layout
  property color color: Theme.fg
  property bool numbered: false
  property int limit: 8
  property real smallest: 4

  readonly property var valid: layout.filter(output => output.width > 0 && output.height > 0 && isFinite(output.x) && isFinite(output.y))
  readonly property var on: valid.filter(output => output.enabled)
  readonly property var off: valid.filter(output => !output.enabled).slice(0, Math.max(0, limit - on.length))
  readonly property real minX: Math.min(...on.map(output => output.x))
  readonly property real minY: Math.min(...on.map(output => output.y))
  readonly property real maxX: Math.max(...on.map(output => output.x + output.width))
  readonly property real gap: 240
  readonly property var placed: on.length > limit ? [] : [
    ...on.map(output => Object.assign({}, output, { x: output.x - minX, y: output.y - minY })),
    ...off.map((output, index) => Object.assign({}, output, {
      x: (on.length > 0 ? maxX - minX + gap : 0) + off.slice(0, index).reduce((sum, other) => sum + other.width + gap, 0),
      y: 0,
    })),
  ]
  readonly property real totalWidth: Math.max(1, ...placed.map(output => output.x + output.width))
  readonly property real totalHeight: Math.max(1, ...placed.map(output => output.y + output.height))
  readonly property real ratio: Math.min(width / totalWidth, height / totalHeight)
  readonly property bool drawn: placed.length > 0 && Math.min(...placed.map(output => Math.min(output.width, output.height))) * ratio >= smallest

  Item {
    anchors.centerIn: parent
    visible: root.drawn
    width: root.totalWidth * root.ratio
    height: root.totalHeight * root.ratio

    Repeater {
      model: root.drawn ? root.placed : []

      Rectangle {
        id: output

        required property var modelData

        // A sliver between neighbours, so two outputs side by side read as two.
        x: Math.round(modelData.x * root.ratio) + 1
        y: Math.round(modelData.y * root.ratio) + 1
        width: Math.max(1, Math.round(modelData.width * root.ratio) - 2)
        height: Math.max(1, Math.round(modelData.height * root.ratio) - 2)
        radius: Math.min(6, height / 6)
        color: modelData.enabled ? root.color : "transparent"
        border.width: modelData.enabled ? 0 : 1
        border.color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.6)

        Text {
          anchors.centerIn: parent
          visible: root.numbered && output.height >= 20 && output.width >= 20
          text: output.modelData.enabled ? output.modelData.number : "off"
          color: output.modelData.enabled ? Theme.bg : Theme.fgDim
          font.family: Theme.body.family
          font.weight: Font.Bold
          font.pixelSize: Math.min(22, Math.round(output.height * 0.4))
        }
      }
    }
  }

  Text {
    anchors.fill: parent
    visible: !root.drawn && root.on.length > 0
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: root.numbered ? `${root.on.length} displays` : root.on.length
    color: root.color
    font.family: Theme.body.family
    font.weight: Font.Bold
    font.pixelSize: 28
    fontSizeMode: Text.Fit
    minimumPixelSize: 6
  }
}
