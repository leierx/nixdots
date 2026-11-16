import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

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

    ClippingRectangle {
      visible: !!root.modelData.thumbnail
      implicitWidth: 64
      implicitHeight: 36
      radius: 6
      color: Theme.card

      Image {
        anchors.fill: parent
        source: root.modelData.thumbnail ?? ""
        sourceSize.width: 128
        fillMode: Image.PreserveAspectCrop
        // Pictures can be large; the row shows without waiting for one.
        asynchronous: true
      }
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
