pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
import Quickshell
import Quickshell.Wayland
import qs.common

// The control centre's popover under its bar button: GNOME's quick settings.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popover drops below.
  required property real top
  // The most the card may take: what the screen leaves under the bar.
  readonly property real available: height - top - 2 * Theme.gap
  readonly property bool open: Panels.active === name
  property real shown: 0
  // The open menu, held while the card fades out, as Controls shuts it at once.
  property string menu: ""

  Binding on menu {
    when: root.open
    value: Controls.menu
    restoreMode: Binding.RestoreNone
  }

  // What the card stacks, each menu in a slot of its own under the row that opens it, so one eases shut as the next eases open; by id, so an open menu outlives every change around it.
  readonly property var sections: {
    const list = [{ id: "header", kind: "header" }, { id: "levels", kind: "levels" }, { id: "menu:output", kind: "menu", key: "output" }, { id: "menu:input", kind: "menu", key: "input" }];
    for (let i = 0; i < Controls.toggles.length; i += 2) {
      const row = Controls.toggles.slice(i, i + 2);
      list.push({ id: `toggles:${i}`, kind: "toggles", items: row });
      for (const toggle of row) if (toggle.menu) list.push({ id: `menu:${toggle.key}`, kind: "menu", key: toggle.key });
    }
    if (Privacy.kinds.length > 0) list.push({ id: "inuse", kind: "inuse" });
    if (Media.player) list.push({ id: "media", kind: "media" });
    return list;
  }

  signal hidden()

  onOpenChanged: {
    (open ? closing : opening).stop();
    // Closed before it moved, it has nothing to animate, and would never report itself hidden.
    if (!open && shown === 0) Qt.callLater(root.hideClosed);
    else (open ? opening : closing).start();
  }
  onShownChanged: if (shown === 0 && !open) hidden()
  // A window Hyprland has closed stays closed, so the next open needs a new one.
  onClosed: hidden()
  Component.onCompleted: {
    if (open) opening.start();
    else Qt.callLater(root.hideClosed);
  }

  function hideClosed(): void {
    if (!root.open) root.hidden();
  }

  // Kept whole in view in the card too, which scrolls on a short screen.
  function reveal(item: Item): void {
    const top = item.mapToItem(column, 0, 0).y;
    const bottom = top + item.height;
    if (bottom > scroller.contentY + scroller.height) scroller.contentY = Math.min(bottom - scroller.height, scroller.contentHeight - scroller.height);
    if (top < scroller.contentY) scroller.contentY = top;
  }

  card: box
  // While closing, clicks already go to the windows below.
  mask: open ? null : nothing
  WlrLayershell.namespace: "quickshell:controls"
  WlrLayershell.keyboardFocus: open ? root.keyboard : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  // Not a Behavior: one whose duration follows `open` may start before that duration updates.
  NumberAnimation {
    id: opening

    target: root
    property: "shown"
    to: 1
    duration: Theme.open
    easing.type: Easing.OutQuint
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: Theme.close
    easing.type: Easing.InCubic
  }

  Card {
    id: box

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: Math.min(Math.round(28 * Theme.em), root.width - 2 * Theme.gap)
    height: Math.min(column.implicitHeight + 2 * Theme.padding, root.available)
    radius: Theme.windowRadius
    focus: true
    opacity: root.shown
    // Grown out of its button.
    transform: Scale {
      origin.x: root.anchorX - box.x
      origin.y: -Theme.gap
      xScale: 0.9 + 0.1 * root.shown
      yScale: 0.9 + 0.1 * root.shown
    }

    Flickable {
      id: scroller

      // In the card's padding rather than over the rows.
      QQC.ScrollIndicator.vertical: ScrollBar {
        parent: box
        x: box.width - width - 3
        y: Theme.padding
        height: scroller.height
        held: true
      }
      anchors.fill: parent
      anchors.margins: Theme.padding
      contentHeight: column.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Column {
        id: column

        // Everything but the menus, which take what is left of the screen; measured a frame later, as a menu's own height feeds back into the column.
        property real fixed: 0

        function measure(): void {
          column.fixed = column.children.filter(child => child.menu === false).reduce((sum, child) => sum + child.height, 0);
        }

        onChildrenChanged: Qt.callLater(column.measure)

        width: scroller.width

        Repeater {
          model: ScriptModel {
            values: root.sections
            objectProp: "id"
          }

          // The gap above each is its own, so a menu eases open from nothing, gap and all.
          Item {
            id: section

            required property var modelData
            readonly property bool menu: modelData.kind === "menu"
            readonly property real gap: modelData.kind === "header" ? 0 : 12
            property real opened: !menu || root.menu === modelData.key ? 1 : 0

            Behavior on opened {
              NumberAnimation {
                duration: Theme.move
                easing.type: Easing.OutCubic
              }
            }

            width: column.width
            height: (gap + ((loader.item as Item)?.height ?? 0)) * opened
            clip: menu
            onHeightChanged: if (!menu) Qt.callLater(column.measure)
            Component.onCompleted: Qt.callLater(column.measure)

            Loader {
              id: loader

              y: section.gap
              width: parent.width
              active: section.opened > 0
              sourceComponent: ({ header: headerSection, levels: levels, toggles: toggleRow, menu: menuSection, inuse: inUseSection, media: media })[section.modelData.kind]
            }

            Component {
              id: headerSection

              Header {}
            }

            Component {
              id: inUseSection

              InUse {}
            }

            Component {
              id: levels

              Levels {
                menu: root.menu
              }
            }

            Component {
              id: media

              MediaCard {}
            }

            Component {
              id: menuSection

              Menu {
                key: section.modelData.key
                limit: root.available - 2 * Theme.padding - column.fixed - section.gap
                onWantsInView: item => root.reveal(item)
              }
            }

            Component {
              id: toggleRow

              Row {
                spacing: 12

                Repeater {
                  model: ScriptModel {
                    values: section.modelData.items
                    objectProp: "key"
                  }

                  Pill {
                    required property var modelData

                    width: (column.width - 12) / 2
                    toggle: modelData
                    open: root.menu === modelData.key
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
