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

  readonly property var valid: layout.filter(output => output.width > 0 && output.height > 0)
  readonly property var on: valid.filter(output => output.enabled)
  readonly property var shown: on.length > limit ? [] : [...on, ...valid.filter(output => !output.enabled)].slice(0, limit)
  readonly property real gap: 240
  // Outputs with no place of their own, turned off and never on elsewhere, go in a row to the right.
  readonly property var placed: {
    const fixed = shown.filter(output => Number.isFinite(output.x) && Number.isFinite(output.y));
    const loose = shown.filter(output => !fixed.includes(output));
    const minX = Math.min(...fixed.map(output => output.x));
    const minY = Math.min(...fixed.map(output => output.y));
    const start = fixed.length > 0 ? Math.max(...fixed.map(output => output.x + output.width)) - minX + gap : 0;
    return [
      ...fixed.map(output => Object.assign({}, output, { x: output.x - minX, y: output.y - minY })),
      ...loose.map((output, index) => Object.assign({}, output, {
        x: start + loose.slice(0, index).reduce((sum, other) => sum + other.width + gap, 0),
        y: 0,
      })),
    ];
  }
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
        border.color: Theme.fgDim

        Column {
          anchors.centerIn: parent
          visible: root.numbered && output.height >= 20 && output.width >= 20

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: output.modelData.enabled ? output.modelData.number : "off"
            textFormat: Text.PlainText
            color: output.modelData.enabled ? Theme.popoverBg : Theme.fgDim
            font.family: Theme.body.family
            font.weight: Font.Bold
            font.pixelSize: Math.min(22, Math.round(output.height * 0.4))
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== "" && output.height >= 60 && implicitWidth <= output.width - 8
            text: output.modelData.connector ?? ""
            textFormat: Text.PlainText
            color: output.modelData.enabled ? Theme.popoverBg : Theme.fgDim
            font: Theme.caption
          }
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
