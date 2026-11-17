import QtQuick
import Quickshell
import qs.common
import qs.weather

Scope {
  // The forecast is fetched from the start, so the first open has it.
  Component.onCompleted: Weather.now

  // Created as it opens, so every group starts collapsed, and unloaded once it has animated closed.
  LazyLoader {
    id: loader

    NotificationCenter {
      onHidden: loader.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active === "center") loader.active = true;
    }
  }
}
