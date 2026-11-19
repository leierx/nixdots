import QtQuick

// A notification read back from the saved history: what the views read of a live one, with nothing left to invoke.
QtObject {
  readonly property bool past: true
  property string appName: ""
  property string appIcon: ""
  property string desktopEntry: ""
  property string summary: ""
  property string body: ""
  property string image: ""
  property int urgency: 1
  readonly property var actions: []
  readonly property var hints: ({})
  readonly property int expireTimeout: -1

  signal closed()

  function dismiss(): void {
    closed();
  }

  function expire(): void {
    closed();
  }
}
