pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import "../common/keep.js" as Keep

Column {
  id: inUse

  // The window of the first app named that has one, by the app's own name or its desktop entry's.
  function windowOf(apps: var): var {
    const toplevels = ToplevelManager.toplevels.values;
    for (const app of apps) {
      const entry = DesktopEntries.heuristicLookup(app);
      const ids = [app, entry?.id ?? "", entry?.startupClass ?? ""].filter(id => id !== "").map(id => id.toLowerCase());
      const found = toplevels.find(toplevel => ids.includes(toplevel.appId.toLowerCase()));
      if (found) return found;
    }
    return null;
  }

  // The kinds as last built, for Keep.
  readonly property var kept: ({})

  spacing: 8

  Text {
    leftPadding: Theme.baseMargin
    text: "In Use"
    color: Theme.fgDim
    font: Theme.heading
  }

  Grid {
    columns: 2
    columnSpacing: Theme.padding
    rowSpacing: Theme.padding

    Repeater {
      model: ScriptModel {
        values: Keep.keep(inUse.kept, Privacy.kinds, "name")
        objectProp: "name"
      }

      // A quick toggle that raises the app's window, dim where it has none.
      Pill {
        id: use

        required property var modelData
        readonly property var window: inUse.windowOf(modelData.apps)

        width: (inUse.width - Theme.padding) / 2
        toggle: ({
          key: `inuse:${use.modelData.name}`,
          title: use.modelData.name === "Screen" ? "Screen Sharing" : use.modelData.name,
          subtitle: use.modelData.apps.map(app => DesktopEntries.heuristicLookup(app)?.name ?? app).join(", ") || "Through the screen sharing portal",
          glyph: use.modelData.glyph,
          glyphColor: Theme.inUse,
          on: false,
          menu: false,
          unavailable: false,
          inert: use.window === null,
          action: () => {
            const window = use.window;
            Panels.close();
            window?.activate();
          }
        })
      }
    }
  }
}
