import QtQuick
import Quickshell
import qs.common

// Created as it opens, so every group starts collapsed, and unloaded once it has animated closed.
Scope {
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
