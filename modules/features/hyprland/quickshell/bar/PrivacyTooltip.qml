pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// Who records what, under the indicator while the pointer is on it.
Tooltip {
  id: root

  function entry(name: string): var {
    return DesktopEntries.heuristicLookup(name);
  }

  available: Privacy.kinds.length > 0

  WlrLayershell.namespace: "quickshell:privacy"

  Column {
    id: rows

    spacing: 10

    Repeater {
      model: Privacy.kinds

      Row {
        id: kind

        required property var modelData

        spacing: 10

        Rectangle {
          width: 28
          height: 28
          radius: height / 2
          color: Theme.button

          Glyph {
            anchors.centerIn: parent
            path: kind.modelData.glyph
            size: 16
            color: Theme.fg
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            text: kind.modelData.name
            color: Theme.fg
            font: Theme.heading
          }

          Row {
            id: names

            // A few, rather than a row running off the screen.
            readonly property int most: 5

            spacing: 8

            Repeater {
              model: kind.modelData.apps.length > 0 ? kind.modelData.apps.slice(0, names.most) : [""]

              Row {
                id: app

                required property string modelData
                readonly property var desktop: modelData ? root.entry(modelData) : null

                spacing: 4

                IconImage {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: app.desktop !== null
                  implicitSize: 16
                  source: app.desktop ? Quickshell.iconPath(app.desktop.icon, true) : ""
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: Math.min(implicitWidth, Math.round(12 * Theme.em))
                  text: app.desktop?.name ?? (app.modelData || "Through the screen sharing portal")
                  elide: Text.ElideRight
                  color: Theme.fgDim
                  font: Theme.caption
                }
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: kind.modelData.apps.length > names.most
              text: `and ${kind.modelData.apps.length - names.most} more`
              color: Theme.fgDim
              font: Theme.caption
            }
          }
        }
      }
    }
  }
}
