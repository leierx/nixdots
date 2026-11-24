pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common
import qs.weather

Scope {
  // The forecast is fetched from the start, so the first open has it.
  Component.onCompleted: Weather.now

  // One per screen, so a clock opens its own and another screen's never moves a window that is still fading out.
  Variants {
    model: Screens.real

    Scope {
      id: one

      required property ShellScreen modelData
      // Taken once: the screen object dangles while its monitor goes.
      property string panel: ""

      Component.onCompleted: {
        panel = `center:${modelData.name}`;
        loader.active = Panels.active === panel;
      }

      // Created as it opens, so every group starts collapsed, and unloaded once it has animated closed.
      LazyLoader {
        id: loader

        NotificationCenter {
          screen: one.modelData
          name: one.panel
          onHidden: loader.active = false
        }
      }

      Connections {
        target: Panels

        function onActiveChanged() {
          if (Panels.active === one.panel) loader.active = true;
        }
      }
    }
  }
}
