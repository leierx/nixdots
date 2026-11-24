import QtQuick

Item {
  id: root

  property string glyph: ""
  property alias text: label.text

  implicitWidth: column.implicitWidth + 2 * Theme.padding
  implicitHeight: column.implicitHeight + 4 * Theme.padding

  Column {
    id: column

    anchors.centerIn: parent
    spacing: Theme.padding

    Glyph {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.glyph !== ""
      path: root.glyph
      size: 64
      color: Theme.fgDim
    }

    Text {
      id: label

      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(implicitWidth, root.width - 2 * Theme.padding)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fgDim
      font: Theme.title3
    }
  }
}
