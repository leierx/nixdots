pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// Every tray item, in a grid under the bar's chevron.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popover drops below.
  required property real top
  required property var items
  readonly property int columns: Math.max(1, Math.min(6, items.length))
  // The menu open over it, which its keys go to.
  property var menu: null
  property Item menuCell: null

  signal pressed(SystemTrayItem item, Item cell, int button, real x, real y, bool keys)

  card: box
  // Shown over its bar without dimming the screen behind.
  WlrLayershell.namespace: "quickshell:tray-overflow"

  onMenuChanged: {
    if (menu) menuKeys.forceActiveFocus();
    else if (menuKeys.activeFocus) (root.menuCell ?? box).forceActiveFocus();
  }

  Card {
    id: box

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: grid.implicitWidth + 2 * Theme.padding
    height: cells.height + 2 * Theme.padding
    radius: Theme.cardRadius
    focus: true

    Item {
      id: menuKeys

      Keys.onPressed: event => {
        event.accepted = root.menu?.key(event) ?? false;
      }
    }

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
          id: cellsRepeater

          model: ScriptModel {
            values: root.items
          }

          Rectangle {
            id: cell

            required property SystemTrayItem modelData
            required property int index
            readonly property bool hovered: area.containsMouse

            function press(button: int, keys: bool): void {
              root.menuCell = cell;
              root.pressed(cell.modelData, cell, button, cell.width / 2, cell.height / 2, keys);
            }

            width: 36
            height: 36
            radius: Theme.smallRadius
            color: area.containsMouse ? Theme.hover : "transparent"
            activeFocusOnTab: true
            onActiveFocusChanged: {
              if (!activeFocus) return;
              if (y < cells.contentY) cells.contentY = y;
              else if (y + height > cells.contentY + cells.height) cells.contentY = y + height - cells.height;
            }
            // Left and right step through the grid as the card's arrows do; up and down by a whole row.
            Keys.onPressed: event => {
              const by = { [Qt.Key_Up]: -root.columns, [Qt.Key_Down]: root.columns }[event.key];
              if (by !== undefined) {
                const next = cellsRepeater.itemAt(cell.index + by);
                if (next) next.forceActiveFocus(Qt.TabFocusReason);
                Panels.keyboard = true;
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                cell.press(Qt.LeftButton, true);
                event.accepted = true;
              } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
                cell.press(Qt.RightButton, true);
                event.accepted = true;
              }
            }

            FocusRing {
              corner: cell.radius
              on: cell.activeFocus
            }

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
              onClicked: mouse => {
                root.menuCell = cell;
                root.pressed(cell.modelData, cell, mouse.button, mouse.x, mouse.y, false);
              }
            }

            TooltipArea {
              text: cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id
            }
          }
        }
      }
    }
  }
}
