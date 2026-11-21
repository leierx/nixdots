pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// GNOME's "In use": a pill per kind of recording, naming the apps; a click raises the first one's window.
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


  spacing: 8

  Text {
    leftPadding: 4
    text: "In Use"
    color: Theme.fgDim
    font: Theme.heading
  }

  Grid {
    columns: 2
    columnSpacing: 12
    rowSpacing: 12

    Repeater {
      model: ScriptModel {
        values: Privacy.kinds
        objectProp: "name"
      }

      Rectangle {
        id: use

        required property var modelData
        readonly property var window: inUse.windowOf(modelData.apps)
        readonly property var names: modelData.apps.map(app => DesktopEntries.heuristicLookup(app)?.name ?? app)

        width: (inUse.width - 12) / 2
        height: 48
        radius: height / 2
        color: area.containsMouse && area.enabled ? Theme.buttonHover : Theme.button

        Behavior on color {
          ColorAnimation {
            duration: Theme.fade
          }
        }

        Glyph {
          id: chip

          x: 14
          anchors.verticalCenter: parent.verticalCenter
          path: use.modelData.glyph
          size: 16
          color: Theme.inUse
        }

        Column {
          anchors.left: chip.right
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter

          Text {
            width: parent.width
            text: use.modelData.name === "Screen" ? "Screen Sharing" : use.modelData.name
            elide: Text.ElideRight
            color: Theme.fg
            font: Theme.heading
          }

          Text {
            width: parent.width
            text: use.names.join(", ") || "Through the screen sharing portal"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.fgDim
            font: Theme.caption
          }
        }

        MouseArea {
          id: area

          objectName: `inuse:${use.modelData.name}`
          anchors.fill: parent
          hoverEnabled: true
          enabled: use.window !== null
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            Panels.close();
            use.window?.activate();
          }
        }
      }
    }
  }
}
