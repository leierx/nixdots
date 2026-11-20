pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Tray items in the order they came, which every bar shares: Quickshell sorts its model by category and id.
Singleton {
  id: root

  property var items: []
  readonly property var current: SystemTray.items.values

  function update(): void {
    const now = root.current;
    const kept = root.items.filter(item => now.includes(item));
    root.items = [...kept, ...now.filter(item => !kept.includes(item))];
  }

  onCurrentChanged: update()
  Component.onCompleted: update()
}
