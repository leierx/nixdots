import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

// One row of a MenuList: an icon if the row has one, a title and an optional
// subtitle, highlighted while it is the selected row.
Rectangle {
  id: root

  required property var modelData
  required property int index

  signal clicked()

  height: Theme.rowHeight
  radius: 8
  // ListView attaches isCurrentItem to the delegate itself, which this is.
  color: ListView.isCurrentItem ? Theme.selected : "transparent"

  MouseArea {
    anchors.fill: parent
    onClicked: root.clicked()
  }

  // Leaves out the icon, and the space for it, when the row has none.
  RowLayout {
    anchors {
      fill: parent
      leftMargin: 12
      rightMargin: 12
    }
    spacing: 14

    IconImage {
      visible: !!root.modelData.icon
      source: root.modelData.icon ?? ""
      implicitSize: Theme.iconSize
    }

    Column {
      Layout.fillWidth: true
      spacing: 2

      Text {
        width: parent.width
        text: root.modelData.title
        color: Theme.fg
        elide: Text.ElideRight
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontSize
        }
      }

      Text {
        width: parent.width
        text: root.modelData.subtitle ?? ""
        visible: text !== ""
        color: Theme.fgDim
        elide: Text.ElideRight
        font {
          family: Theme.fontFamily
          pixelSize: Theme.subtitleSize
        }
      }
    }
  }
}
