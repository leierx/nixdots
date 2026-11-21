import QtQuick

// What just happened and a button to take it back, as libadwaita's toast: gone after five seconds, on its button, or when its panel closes.
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

  implicitWidth: row.implicitWidth + Theme.padding + Theme.basePadding
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
    x: Theme.padding
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
      flat: true
      text: root.action
      font: Theme.body
      onClicked: {
        timer.stop();
        root.acted();
      }
    }
  }
}
