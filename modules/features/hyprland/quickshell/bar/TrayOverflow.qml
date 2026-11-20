pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// The tray items past the bar's four, in a grid under its button.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popover drops below.
  required property real top
  required property var items
  readonly property int columns: Math.max(1, Math.min(6, items.length))

  signal pressed(SystemTrayItem item, Item cell, int button, real x, real y)

  card: box
  // Shown over its bar without dimming the screen behind.
  WlrLayershell.namespace: "quickshell:tray-overflow"

  Card {
    id: box

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: grid.implicitWidth + 2 * Theme.padding
    height: cells.height + 2 * Theme.padding
    radius: Theme.cardRadius
    focus: true

    // As tall as the screen leaves room for; past it the grid scrolls.
    Flickable {
      id: cells

      x: Theme.padding
      y: Theme.padding
      width: grid.implicitWidth
      height: Math.min(contentHeight, Math.max(36, root.height - root.top - 2 * Theme.gap - 2 * Theme.padding))
      contentHeight: grid.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Grid {
        id: grid

        columns: root.columns
        spacing: 4

        Repeater {
          model: ScriptModel {
            values: root.items
          }

          Rectangle {
            id: cell

            required property SystemTrayItem modelData
            readonly property bool hovered: area.containsMouse

            width: 36
            height: 36
            radius: Theme.smallRadius
            color: area.containsMouse ? Theme.hover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: Theme.fade
              }
            }

            IconImage {
              anchors.centerIn: parent
              implicitSize: 20
              source: cell.modelData.icon
              backer.retainWhileLoading: true
            }

            MouseArea {
              id: area

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.ArrowCursor
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
              onClicked: mouse => root.pressed(cell.modelData, cell, mouse.button, mouse.x, mouse.y)
            }
          }
        }
      }
    }
  }
}
