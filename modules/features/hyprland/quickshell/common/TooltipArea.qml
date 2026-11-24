import QtQuick
import Quickshell

Item {
  id: root

  property string text: ""
  readonly property Item owner: parent
  // Untyped, as qmllint types the window as a plain QObject.
  readonly property var shown: QsWindow.window

  onTextChanged: if (Tooltips.owner === owner) Tooltips.text = text
  Component.onDestruction: Tooltips.cancel(owner)

  // On the owner, not on an item over it: Qt hovers one item and its ancestors, so a sibling on top kept the owner's MouseArea from ever being hovered, and the hover a press gave it was never taken back.
  HoverHandler {
    objectName: "tooltip"
    parent: root.owner
    enabled: root.text !== ""
    onHoveredChanged: {
      if (hovered) Tooltips.request(root.owner, root.text, root.shown);
      else Tooltips.cancel(root.owner);
    }
  }
}
