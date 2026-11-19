pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common

// Who records what, under the indicator while the pointer is on it.
PopupWindow {
  id: root

  required property Item anchorItem
  required property var window
  property bool shown: false
  // A pass over the bar on the way elsewhere opens nothing.
  property bool settled: false

  function entry(name: string): var {
    return DesktopEntries.heuristicLookup(name);
  }

  onShownChanged: {
    if (shown) delay.restart();
    else {
      delay.stop();
      settled = false;
    }
  }

  anchor.window: window
  anchor.item: anchorItem
  // qmllint disable incompatible-type
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  // qmllint enable incompatible-type
  anchor.margins.top: 6
  visible: shown && settled && Privacy.kinds.length > 0
  implicitWidth: card.implicitWidth + 48
  implicitHeight: card.implicitHeight + 48
  color: "transparent"

  Timer {
    id: delay

    interval: 250
    onTriggered: root.settled = true
  }

  Card {
    id: card

    x: 24
    y: 8
    implicitWidth: rows.implicitWidth + 2 * Theme.padding
    implicitHeight: rows.implicitHeight + 2 * Theme.padding
    radius: Theme.cardRadius

    Column {
      id: rows

      x: Theme.padding
      y: Theme.padding
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
            radius: 14
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
              spacing: 8

              Repeater {
                model: kind.modelData.apps.length > 0 ? kind.modelData.apps : [""]

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
                    text: app.desktop?.name ?? (app.modelData || "Through the screen sharing portal")
                    color: Theme.fgDim
                    font: Theme.caption
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
