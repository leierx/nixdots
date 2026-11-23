pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common
import qs.weather

Scope {
  id: root

  // The bar whose clock opened it, taken as it opens; the closing one keeps it as another screen is asked for.
  property string screenName: ""

  // The forecast is fetched from the start, so the first open has it.
  Component.onCompleted: Weather.now

  // Created as it opens, so every group starts collapsed, and unloaded once it has animated closed.
  LazyLoader {
    id: loader

    NotificationCenter {
      screen: Screens.real.find(screen => screen.name === root.screenName) ?? null
      onHidden: loader.active = false
    }
  }

  Connections {
    target: Panels

    function onActiveChanged() {
      if (Panels.active !== "center") return;
      root.screenName = Panels.screen;
      loader.active = true;
    }
  }
}
