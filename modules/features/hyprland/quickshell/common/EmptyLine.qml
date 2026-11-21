import QtQuick

// What an empty menu says: one dim line where its first row would be, quiet, as the toggle and the header already show its symbol (ours over gs .bt-menu-placeholder).
Item {
  property alias text: label.text

  implicitWidth: label.implicitWidth + 2 * Theme.padding
  implicitHeight: Theme.menuRowHeight

  Text {
    id: label

    anchors.fill: parent
    anchors.leftMargin: Theme.padding
    anchors.rightMargin: Theme.padding
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Theme.fgDim
    font: Theme.body
  }
}
