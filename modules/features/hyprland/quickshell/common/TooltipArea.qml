import QtQuick
import Quickshell

// Asks for the tooltip while the pointer rests on what it is in, and lets it go as the pointer leaves, presses or it goes.
Item {
  id: root

  property string text: ""
  readonly property Item owner: parent
  // Untyped, as qmllint types the window as a plain QObject.
  readonly property var shown: QsWindow.window

  anchors.fill: parent
  onTextChanged: if (Tooltips.owner === owner) Tooltips.text = text
  Component.onDestruction: Tooltips.cancel(owner)

  HoverHandler {
    enabled: root.text !== ""
    onHoveredChanged: {
      if (hovered) Tooltips.request(root.owner, root.text, root.shown?.screen?.name ?? "");
      else Tooltips.cancel(root.owner);
    }
  }
}
