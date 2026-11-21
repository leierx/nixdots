import QtQuick

// libadwaita's entry: the button's shade, ringed in the accent while it has the keyboard; a password one has an eye to show it.
Rectangle {
  id: root

  property alias text: field.text
  property string placeholder: ""
  property bool password: false
  property bool revealed: false
  readonly property alias input: field

  signal accepted()

  implicitHeight: 36
  radius: Theme.buttonRadius
  color: Theme.button
  border.width: field.activeFocus ? 2 : 0
  border.color: Theme.accentBg

  TextInput {
    id: field

    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: root.password ? 36 : 12
    anchors.verticalCenter: parent.verticalCenter
    echoMode: root.password && !root.revealed ? TextInput.Password : TextInput.Normal
    color: Theme.fg
    selectionColor: Theme.accentBg
    selectedTextColor: Theme.accentFg
    font: Theme.body
    clip: true
    onAccepted: root.accepted()
  }

  Text {
    anchors.fill: field
    verticalAlignment: Text.AlignVCenter
    visible: field.text === ""
    text: root.placeholder
    elide: Text.ElideRight
    color: Theme.fgDim
    font: Theme.body
  }

  Item {
    anchors.right: parent.right
    width: 36
    height: parent.height
    visible: root.password

    Glyph {
      anchors.centerIn: parent
      path: root.revealed ? Symbols.visibilityOff : Symbols.visibility
      size: 16
      color: Theme.fgDim
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.revealed = !root.revealed
    }
  }
}
