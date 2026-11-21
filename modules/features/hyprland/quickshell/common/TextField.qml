import QtQuick
import qs.nix

// Shell's %entry, or as `search` its search entry: a pill led by the search symbol; ringed while it has the keyboard, and a password one has an eye to show it.
Rectangle {
  id: root

  property alias text: field.text
  property string placeholder: ""
  property bool password: false
  property bool revealed: false
  property bool search: false
  // The mouse's, unless something (the gallery) holds a look.
  property bool hovered: hover.hovered
  readonly property alias input: field

  signal accepted()

  implicitHeight: 36
  radius: search ? height / 2 : Theme.baseRadius
  color: hovered && !field.activeFocus ? Theme.buttonHoverBg : Theme.buttonBg
  border.width: field.activeFocus ? 2 : 0
  border.color: Theme.focusRing

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
    onAccepted: root.accepted()
  }

  Text {
    anchors.fill: field
    verticalAlignment: Text.AlignVCenter
    visible: field.text === ""
    text: root.placeholder
    elide: Text.ElideRight
    color: Theme.placeholder
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

    TooltipArea {
      text: root.revealed ? "Hide Password" : "Show Password"
    }
  }
}
