import QtQuick
import qs.nix

// What just happened, a button to take it back and a round close, as libadwaita's toast: gone after five seconds, on either button, or when its panel closes.
Rectangle {
  id: root

  property string text: ""
  property string action: ""
  readonly property bool shown: timer.running

  signal acted()
  signal expired()

  function show(): void {
    timer.restart();
  }

  function dismiss(): void {
    if (!timer.running) return;
    timer.stop();
    root.expired();
  }

  // adw: 12 px padding and 6 px round each child on the left, 6 px on the right.
  implicitWidth: row.implicitWidth + Theme.padding + 2 * Theme.basePadding
  implicitHeight: Theme.buttonHeight + 2 * Theme.basePadding
  radius: height / 2
  color: Theme.toastBg
  visible: shown

  Timer {
    id: timer

    interval: 5000
    onTriggered: root.expired()
  }

  Row {
    id: row

    anchors.verticalCenter: parent.verticalCenter
    x: Theme.padding + Theme.basePadding
    spacing: Theme.padding

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: Theme.fg
      font: Theme.heading
    }

    Button {
      objectName: `action:${root.action}`
      anchors.verticalCenter: parent.verticalCenter
      text: root.action
      onClicked: {
        timer.stop();
        root.acted();
      }
    }

    IconButton {
      objectName: "action:Dismiss"
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: Theme.buttonHeight
      flat: true
      glyph: Symbols.close
      tooltip: "Dismiss"
      onClicked: root.dismiss()
    }
  }
}
