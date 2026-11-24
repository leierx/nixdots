pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
import Quickshell
import Quickshell.Wayland
import qs.common

// The control centre's popover under its bar button: GNOME's quick settings.
Popover {
  id: root

  required property real anchorX
  // The bar's height, which the popover drops below.
  required property real top
  // The most the card may take: what the screen leaves under the bar.
  readonly property real available: height - top - 2 * Theme.rise
  // The open menu, held while the card fades out, as Controls shuts it at once.
  property string menu: ""

  Binding on menu {
    when: root.open
    value: Controls.menu
    restoreMode: Binding.RestoreNone
  }

  // What the card stacks, a menu slot under each row that opens one: menus of different rows ease shut and open apart, the same row's swap in one slot that eases to the new height; by id, so an open menu outlives every change around it.
  readonly property var sections: {
    const list = [{ id: "header", kind: "header" }, { id: "levels", kind: "levels" }, { id: "menu:levels", kind: "menu", keys: ["sound"] }];
    for (let i = 0; i < Controls.toggles.length; i += 2) {
      const row = Controls.toggles.slice(i, i + 2);
      list.push({ id: `toggles:${i}`, kind: "toggles", items: row });
      const keys = row.filter(toggle => toggle.menu).map(toggle => toggle.key);
      // By the row, so a slot outlives its pills moving between rows.
      if (keys.length > 0) list.push({ id: `menu:${i}`, kind: "menu", keys });
    }
    if (Privacy.kinds.length > 0) list.push({ id: "inuse", kind: "inuse" });
    return list;
  }

  // Kept whole in view in the card too, which scrolls on a short screen.
  function reveal(item: Item): void {
    const top = item.mapToItem(column, 0, 0).y;
    const bottom = top + item.height;
    if (bottom > scroller.contentY + scroller.height) scroller.contentY = Math.min(bottom - scroller.height, scroller.contentHeight - scroller.height);
    if (top < scroller.contentY) scroller.contentY = top;
  }

  card: box
  WlrLayershell.namespace: "quickshell:controls"

  Card {
    id: box

    x: Math.max(Theme.rise, Math.min(root.anchorX - width / 2, root.width - width - Theme.rise))
    y: root.top + Theme.rise
    width: Math.min(2 * Theme.toggleWidth + Theme.padding + 2 * Theme.quickSettingsPadding, root.width - 2 * Theme.rise)
    height: Math.min(column.implicitHeight + 2 * Theme.quickSettingsPadding, root.available)
    radius: Theme.quickSettingsRadius
    focus: true
    back: () => {
      if (Controls.menu === "") return false;
      Controls.show(Controls.menu);
      return true;
    }
    opacity: root.shown
    // BoxPointer's: a fade and a slide down from the bar by its rise.
    transform: Translate {
      y: -Theme.rise * (1 - root.shown)
    }

    Flickable {
      id: scroller

      // In the card's padding rather than over the rows.
      QQC.ScrollIndicator.vertical: ScrollBar {
        parent: box
        x: box.width - width - 3
        y: Theme.quickSettingsPadding
        height: scroller.height
        // Once it has opened: the column measures itself a frame in, and meanwhile looked taller than the card, flashing the bar.
        held: root.shown === 1
      }
      anchors.fill: parent
      anchors.margins: Theme.quickSettingsPadding
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
            readonly property real gap: modelData.kind === "header" ? 0 : Theme.padding
            readonly property var keys: modelData.keys ?? []
            readonly property bool mine: menu && keys.includes(root.menu)
            // The menu it shows, held while it eases shut.
            property string held: ""

            Binding on held {
              when: section.mine
              value: root.menu
              restoreMode: Binding.RestoreNone
            }

            property real opened: !menu || mine ? 1 : 0

            Behavior on opened {
              NumberAnimation {
                duration: Theme.popupTime
                easing.type: Easing.OutQuad
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
              sourceComponent: ({ header: headerSection, levels: levels, toggles: toggleRow, menu: menuSection, inuse: inUseSection })[section.modelData.kind]
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
              id: menuSection

              Item {
                id: menus

                readonly property real natural: each.count > 0 ? (((each.itemAt(section.keys.indexOf(section.held)) as Loader)?.item as Item)?.height ?? 0) : 0
                property real eased: natural

                // Only while it stays open, as another of its row's menus takes the slot.
                Behavior on eased {
                  enabled: section.opened === 1

                  NumberAnimation {
                    duration: Theme.popupTime
                    easing.type: Easing.OutQuad
                  }
                }

                height: eased

                Repeater {
                  id: each

                  model: ScriptModel {
                    values: section.keys
                  }

                  Loader {
                    id: one

                    required property string modelData

                    width: menus.width
                    active: section.held === one.modelData
                    visible: active
                    sourceComponent: Component {
                      Menu {
                        key: one.modelData
                        limit: root.available - 2 * Theme.quickSettingsPadding - column.fixed - section.gap
                        onWantsInView: item => root.reveal(item)
                      }
                    }
                  }
                }
              }
            }

            Component {
              id: toggleRow

              Row {
                spacing: Theme.padding

                Repeater {
                  model: ScriptModel {
                    values: section.modelData.items
                    objectProp: "key"
                  }

                  Pill {
                    required property var modelData

                    width: (column.width - Theme.padding) / 2
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
