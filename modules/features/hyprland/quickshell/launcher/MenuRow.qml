import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

// One row of a MenuList: an icon if the row has one, a title and an optional
// subtitle, highlighted while it is the selected row.
Rectangle {
  id: root

  required property var modelData
  required property int index

  signal clicked()

  radius: Theme.buttonRadius
  // ListView attaches isCurrentItem to the delegate itself, which this is.
  color: ListView.isCurrentItem ? (area.containsMouse ? Theme.selectedHover : Theme.selected) : area.containsMouse ? Theme.hover : "transparent"

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }

  // Leaves out the icon, and the space for it, when the row has none.
  RowLayout {
    anchors {
      fill: parent
      leftMargin: 12
      rightMargin: 12
    }
    spacing: 12

    IconImage {
      visible: !!root.modelData.icon
      source: root.modelData.icon ?? ""
      implicitSize: 32
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Text {
        Layout.fillWidth: true
        text: root.modelData.title
        textFormat: Text.PlainText
        color: Theme.fg
        elide: Text.ElideRight
        font: Theme.body
      }

      Text {
        Layout.fillWidth: true
        text: root.modelData.subtitle ?? ""
        textFormat: Text.PlainText
        visible: text !== ""
        color: Theme.fgDim
        elide: Text.ElideRight
        font: Theme.caption
      }
    }
  }
}
