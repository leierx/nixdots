pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// Who records what, under the indicator while the pointer is on it. A layer of its own on the bar's
// screen, as a PopupWindow lands off by the monitor's x times QT_SCALE_FACTOR - 1.
PanelWindow {
  id: root

  required property Item anchorItem
  property bool shown: false
  // The indicator's middle, in the bar's and so the screen's coordinates, taken as it opens.
  property real anchorX: 0
  // A pass over the bar on the way elsewhere opens nothing.
  property bool settled: false

  function entry(name: string): var {
    return DesktopEntries.heuristicLookup(name);
  }

  onShownChanged: {
    if (shown) {
      anchorX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
      delay.restart();
    }
    else {
      delay.stop();
      settled = false;
    }
  }

  anchors {
    top: true
    left: true
    right: true
  }
  // Below the bar, over windows.
  exclusiveZone: 0
  visible: shown && settled && Privacy.kinds.length > 0
  implicitHeight: card.implicitHeight + 48
  color: "transparent"
  // Nothing in it takes a click.
  mask: Region {}

  WlrLayershell.namespace: "quickshell:privacy"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Timer {
    id: delay

    interval: 250
    onTriggered: root.settled = true
  }

  Card {
    id: card

    // Centred under the indicator, and kept on the screen.
    x: Math.max(Theme.gap, Math.min(root.width - width - Theme.gap, root.anchorX - width / 2))
    y: 6
    width: implicitWidth
    height: implicitHeight
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
}
