pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// The tray on the bar itself, left of the status button, a quiet pill: its first three icons always, a count of the rest, and all of them as the pointer reaches the bar's right end, a strip that scrolls sideways past 12 em, lingering a moment after the pointer leaves so a near miss still finds it.
Item {
  id: root

  required property ShellScreen screen
  // The pointer is on the bar's right end (BarWindow's zone).
  property bool wanted: false
  // Null once the item leaves the tray.
  property SystemTrayItem menuItem: null
  // The cell it opened from, which keeps the menu open while the pointer rests on it.
  property var menuIcon: null
  property point menuAnchor
  // A name per screen, so a menu on one monitor closes one open on another; set once, so it outlives the screen.
  property string menuPanel: ""

  // In the order they came.
  readonly property var items: TrayOrder.items.filter(item => item.status !== Status.Passive)
  readonly property bool menuOpen: menuItem !== null && Panels.active === menuPanel
  readonly property int always: 3
  readonly property bool expanded: items.length > always && (wanted || linger.running || menuOpen)
  // Waiting for the pointer, said as "+N" after the third.
  readonly property int more: expanded ? 0 : Math.max(0, items.length - always)
  readonly property real most: Math.round(12 * Theme.em)
  readonly property real cell: Theme.barItemHeight
  readonly property real offset: cells.contentX
  readonly property bool scrolls: expanded && cells.contentWidth > cells.width + 0.5
  readonly property real strip: expanded ? Math.min(row.implicitWidth, most) : Math.min(row.implicitWidth, always * cell + (always - 1) * row.spacing)

  visible: items.length > 0
  implicitWidth: items.length === 0 ? 0 : fill.width + Theme.basePadding
  onExpandedChanged: if (!expanded) cells.contentX = 0
  implicitHeight: cell
  clip: true
  Component.onCompleted: menuPanel = `tray-menu:${screen.name}`
  // Gone with its monitor, the menu would otherwise stay open in Panels.
  Component.onDestruction: if (Panels.active === menuPanel) Panels.close()
  onItemsChanged: if (items.length === 0 && Panels.active === menuPanel) Panels.close()
  onWantedChanged: {
    if (wanted) linger.stop();
    else linger.restart();
  }

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Theme.popupTime
      easing.type: Easing.OutQuad
    }
  }

  // A moment's grace after the pointer leaves the bar's end.
  Timer {
    id: linger

    interval: 600
  }

  function press(item: SystemTrayItem, icon: Item, button: int): void {
    const opensMenu = item.hasMenu && (button === Qt.RightButton || (button === Qt.LeftButton && item.onlyMenu));
    if (opensMenu && root.menuOpen && root.menuItem === item) {
      Panels.close();
    } else if (opensMenu) {
      // Flush under the bar, from the icon's left edge; every window here starts at the screen's corner.
      root.menuAnchor = Qt.point(icon.mapToItem(null, 0, 0).x, root.Window.height);
      root.menuIcon = icon;
      root.menuItem = item;
      Panels.open(root.menuPanel);
    } else {
      Panels.close();
      if (button === Qt.MiddleButton) item.secondaryActivate();
      else if (button === Qt.LeftButton && !item.onlyMenu) item.activate();
    }
  }

  WheelSteps {
    id: notches
  }

  // The wheel scrolls the strip sideways, a cell a notch.
  WheelHandler {
    enabled: root.expanded
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      const steps = notches.steps(event);
      if (steps !== 0) cells.contentX = Math.max(0, Math.min(cells.contentWidth - cells.width, cells.contentX - steps * (root.cell + row.spacing)));
    }
  }

  // The pill behind the icons and the count: the bar button's rest shade (ours: GNOME has no tray), so the tray reads as one thing beside the status button.
  ClippingRectangle {
    id: fill

    width: root.strip + (root.more > 0 ? count.implicitWidth + Theme.basePadding : 0)
    height: root.cell
    radius: height / 2
    color: Theme.buttonBg

    Flickable {
      id: cells

      width: root.strip
      height: root.cell
      contentWidth: row.implicitWidth
      interactive: root.scrolls
      flickableDirection: Flickable.HorizontalFlick
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Row {
        id: row

        spacing: 2

        Repeater {
          model: ScriptModel {
            values: root.items
          }

          Rectangle {
            id: cell

            required property SystemTrayItem modelData
            readonly property bool hovered: area.containsMouse
            readonly property bool opened: root.menuOpen && root.menuItem === cell.modelData

            width: root.cell
            height: root.cell
            radius: height / 2
            color: cell.opened ? Theme.panelActiveBg : area.containsMouse ? Theme.panelHoverBg : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: Theme.panelButtonTime
              }
            }

            IconImage {
              anchors.centerIn: parent
              implicitSize: 16
              source: cell.modelData.icon
              backer.retainWhileLoading: true
            }

            MouseArea {
              id: area

              anchors.fill: parent
              hoverEnabled: true
              // Few tray icons do anything on a left click, so they keep the arrow.
              cursorShape: Qt.ArrowCursor
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
              onClicked: mouse => root.press(cell.modelData, cell, mouse.button)
            }

            TooltipArea {
              text: cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id
            }
          }
        }
      }
    }

    Text {
      id: count

      x: root.strip
      anchors.verticalCenter: parent.verticalCenter
      visible: root.more > 0
      text: `+${root.more}`
      color: Theme.fgDim
      font: Theme.caption
    }

    // The ends fade where more lies beyond them.
    Rectangle {
      width: 14
      height: root.cell
      visible: cells.contentX > 0
      color: "transparent"
      gradient: Gradient {
        orientation: Gradient.Horizontal

        GradientStop {
          position: 0
          color: Qt.tint(Theme.panelBg, Theme.buttonBg)
        }
        GradientStop {
          position: 1
          color: "transparent"
        }
      }
    }

    Rectangle {
      x: cells.width - width
      width: 14
      height: root.cell
      visible: root.scrolls && cells.contentX < cells.contentWidth - cells.width - 1
      color: "transparent"
      gradient: Gradient {
        orientation: Gradient.Horizontal

        GradientStop {
          position: 0
          color: "transparent"
        }
        GradientStop {
          position: 1
          color: Qt.tint(Theme.panelBg, Theme.buttonBg)
        }
      }
    }
  }

  Variants {
    model: root.menuOpen ? [root.menuItem] : []

    TrayMenu {
      required property SystemTrayItem modelData

      screen: root.screen
      name: root.menuPanel
      // Null for a moment once its item has gone.
      menu: modelData?.menu ?? null
      anchor: root.menuAnchor
      held: root.menuIcon?.hovered ?? false
      onDismissed: {
        root.menuItem = null;
        if (Panels.active === root.menuPanel) Panels.close();
      }
    }
  }
}
