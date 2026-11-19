import QtQuick

// The text as it was, fading out over its newly elided self, so the "…" does not snap in.
Item {
  id: root

  readonly property Text source: parent as Text
  property string whole: source?.text ?? ""

  function play(): void {
    fade.restart();
  }

  anchors.fill: parent
  clip: true
  visible: fade.running

  Text {
    id: ghost

    width: parent.width
    text: root.whole
    textFormat: root.source?.textFormat ?? Text.PlainText
    font: root.source?.font ?? Theme.body
    color: root.source?.color ?? Theme.fg
    linkColor: root.source?.linkColor ?? Theme.accent
    wrapMode: Text.Wrap
  }

  NumberAnimation {
    id: fade

    target: ghost
    property: "opacity"
    from: 1
    to: 0
    duration: Theme.fade
    easing.type: Easing.InOutQuad
  }
}
