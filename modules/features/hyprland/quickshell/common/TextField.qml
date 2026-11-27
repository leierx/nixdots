import QtQuick
import qs.nix

Rectangle {
  id: root

  property alias text: field.text
  property string placeholder: ""
  property bool password: false
  property bool revealed: false
  property bool search: false
  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: hover.hovered
  // The keyboard's, unless the gallery holds the look.
  property bool focused: field.activeFocus
  readonly property alias input: field

  signal accepted()

  implicitHeight: 36
  radius: search ? height / 2 : Theme.baseRadius
  color: hovered && !focused ? Theme.buttonHoverBg : Theme.buttonBg
  border.width: focused ? 2 : 0
  border.color: Theme.focusRing

  Behavior on color {
    ColorAnimation {
      duration: Theme.quickTime
      easing.type: Easing.OutQuad
    }
  }

  HoverHandler {
    id: hover
  }

  Glyph {
    id: lead

    x: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: root.search
    path: Symbols.search
    size: 16
    color: Theme.fgDim
  }

  TextInput {
    id: field

    anchors.left: parent.left
    anchors.leftMargin: root.search ? lead.x + lead.width + Theme.basePadding : 9
    anchors.right: parent.right
    anchors.rightMargin: root.password ? 36 : 9
    anchors.verticalCenter: parent.verticalCenter
    echoMode: root.password && !root.revealed ? TextInput.Password : TextInput.Normal
    color: Theme.fg
    selectionColor: Theme.accentBg
    selectedTextColor: Theme.accentFg
    font: Theme.body
    clip: true
    activeFocusOnTab: root.enabled
    onAccepted: root.accepted()
  }

  Text {
    anchors.fill: field
    verticalAlignment: Text.AlignVCenter
    visible: field.text === ""
    text: root.placeholder
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Theme.placeholder
    font: Theme.body
  }

  IconButton {
    objectName: "reveal"
    anchors.right: parent.right
    anchors.rightMargin: (parent.height - height) / 2
    anchors.verticalCenter: parent.verticalCenter
    visible: root.password
    small: true
    flat: true
    glyph: root.revealed ? Symbols.visibilityOff : Symbols.visibility
    foreground: Theme.fgDim
    tooltip: root.revealed ? "Hide Password" : "Show Password"
    onClicked: root.revealed = !root.revealed
  }
}
