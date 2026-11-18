pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

PanelWindow {
  id: root

  required property QsMenuHandle menu
  required property point anchor
  required property string name
  // While the pointer rests on the menu's icon: Hyprland reports none on the menu until the pointer moves.
  property bool held: false
  // The labels of the open submenus rather than their entries: nm-applet rebuilds its whole menu, every entry new, as networks come and go.
  property var path: []
  // Cards register here, as the window's input region is theirs alone.
  property list<Item> cards: []
  // A moment's delay, so passing over rows opens nothing.
  property var pending: null
  readonly property int padding: 6

  // libadwaita's check button: an outlined box (a ring for a radio), filled with the accent once checked.
  component CheckIndicator: Rectangle {
    id: indicator

    property bool radio: false
    property int checkState: Qt.Unchecked
    readonly property bool on: checkState !== Qt.Unchecked

    width: 14
    height: 14
    radius: radio ? 7 : 4
    color: on ? Theme.accentBg : "transparent"
    border.width: on ? 0 : 2
    border.color: Theme.border

    Rectangle {
      anchors.centerIn: parent
      width: 6
      height: 6
      radius: 3
      visible: indicator.radio && indicator.on
      color: Theme.accentFg
    }

    Shape {
      anchors.fill: parent
      visible: !indicator.radio && indicator.on
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeColor: Theme.accentFg
        strokeWidth: 2
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
          path: indicator.checkState === Qt.PartiallyChecked
            ? [Qt.point(4, 7), Qt.point(10, 7)]
            : [Qt.point(3.5, 7.5), Qt.point(6, 10), Qt.point(10.5, 4.5)]
        }
      }
    }
  }

  function apply(level: int, label: string): void {
    root.pending = null;
    root.path = [...root.path.slice(0, level), ...(label ? [label] : [])];
  }

  // A card by depth, as var: Repeater.itemAt() says Item, which has none of a card's properties.
  function level(depth: int): var {
    return levels.itemAt(depth);
  }

  // Closes the submenus from the first whose label its parent no longer has.
  function prune(): void {
    for (let depth = 1; depth <= root.path.length; depth++) {
      if (root.level(depth)?.handle) continue;
      root.path = root.path.slice(0, depth - 1);
      return;
    }
  }

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  mask: Region {
    regions: root.cards.map(card => card.region)
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:menu"
  // Like a GTK menu: the app keeps the keyboard, and the menu goes once the pointer leaves it.
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  // Hyprland closes it with its monitor.
  onClosed: if (Panels.active === root.name) Panels.close()
  // A new menu from the app shares no entries with the old one.
  onMenuChanged: {
    root.path = [];
    if (root.menu === null && Panels.active === root.name) Panels.close();
  }

  Timer {
    id: hoverDelay

    interval: 150
    onTriggered: if (root.pending) root.apply(root.pending.level, root.pending.label)
  }

  Timer {
    running: !inside.hovered && !root.held
    interval: 100
    onTriggered: Panels.close()
  }

  // Only the cards take input, so this is hovered exactly while the pointer is on one; hover reaches ancestors, not siblings beneath.
  Item {
    anchors.fill: parent

    HoverHandler {
      id: inside
    }

    Repeater {
      id: levels

      // Levels by depth, so a card outlives a rebuild of the menu it shows.
      model: ScriptModel {
        values: Array.from({ length: root.path.length + 1 }, (_, depth) => depth)
      }

      Card {
        id: card

        required property int index
        readonly property QsMenuHandle handle: index === 0 ? root.menu : parentCard?.entries.find(entry => entry.hasChildren && entry.text === root.path[index - 1]) ?? null
        // Bumped as rows are made, which itemAt() does not report.
        property int built: 0

        readonly property Region region: Region {
          item: card
        }
        readonly property var parentCard: index > 0 ? root.level(index - 1) : null
        readonly property int direction: {
          const way = parentCard?.direction ?? (root.anchor.x + width + Theme.gap <= root.width ? 1 : -1);
          const fits = way > 0 ? x + 2 * width + Theme.gap <= root.width : x - width - Theme.gap >= 0;
          return fits ? way : -way;
        }
        readonly property bool cascades: entries.some(entry => entry.hasChildren)
        // Without the stray separators apps leave around items they hide.
        readonly property var entries: {
          const entries = [];
          for (const entry of opener.children.values) {
            if (!entry.isSeparator || (entries.length > 0 && !entries[entries.length - 1].isSeparator)) entries.push(entry);
          }
          if (entries.length > 0 && entries[entries.length - 1].isSeparator) entries.pop();
          return entries;
        }
        readonly property real openerY: parentCard?.rowY(handle) ?? 0

        function rowY(entry: var): real {
          const row = card.built > 0 ? rowsRepeater.itemAt(entries.indexOf(entry)) : null;
          return rows.y + (row?.y ?? 0);
        }

        x: {
          if (!parentCard) return root.anchor.x + width + Theme.gap <= root.width ? root.anchor.x : Math.max(Theme.gap, root.anchor.x - width);
          const beside = parentCard.direction > 0 ? parentCard.x + parentCard.width - 4 : parentCard.x - width + 4;
          return Math.max(Theme.gap, Math.min(beside, root.width - width - Theme.gap));
        }
        y: Math.max(Theme.gap, Math.min((parentCard ? parentCard.y + openerY - root.padding : root.anchor.y), root.height - height - Theme.gap))
        width: Math.max(180, rows.implicitWidth) + root.padding * 2
        height: rows.implicitHeight + root.padding * 2
        radius: Theme.cardRadius

        Component.onCompleted: {
          root.cards = [...root.cards, card];
          if (index > 0 && !handle) Qt.callLater(root.prune);
        }
        Component.onDestruction: root.cards = root.cards.filter(other => other !== card)
        // Later, as changing the levels from a binding they feed loops.
        onHandleChanged: if (handle === null && index > 0) Qt.callLater(root.prune)

        QsMenuOpener {
          id: opener

          menu: card.handle
        }

        ColumnLayout {
          id: rows

          anchors {
            fill: parent
            margins: root.padding
          }
          spacing: 0

          Repeater {
            id: rowsRepeater

            onItemAdded: card.built++
            model: ScriptModel {
              values: card.entries
            }

            Item {
              id: entry

              required property QsMenuEntry modelData
              readonly property bool opened: (modelData?.hasChildren ?? false) && root.path[card.index] === modelData.text
              // Room for the arrows, which point right whichever side the submenu opens, as GTK's do.
              readonly property int arrowSpace: card.cascades ? 24 : 0

              Layout.fillWidth: true
              implicitWidth: modelData?.isSeparator ? 0 : content.implicitWidth + 24 + arrowSpace
              implicitHeight: modelData?.isSeparator ? 13 : 32

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                visible: entry.modelData?.isSeparator ?? false
                color: Theme.border
              }

              Rectangle {
                anchors.fill: parent
                visible: !entry.modelData?.isSeparator
                radius: Theme.smallRadius
                color: (entryHover.hovered || entry.opened) && entry.modelData?.enabled ? Theme.hover : "transparent"

                Row {
                  id: content

                  x: 12
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 8
                  opacity: entry.modelData?.enabled ? 1 : 0.5

                  Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    visible: (entry.modelData?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None

                    CheckIndicator {
                      anchors.centerIn: parent
                      radio: entry.modelData?.buttonType === QsMenuButtonType.RadioButton
                      checkState: entry.modelData?.checkState ?? Qt.Unchecked
                    }
                  }

                  Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    visible: !!entry.modelData?.icon

                    IconImage {
                      anchors.fill: parent
                      source: entry.modelData ? entry.modelData.icon : ""
                    }
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData?.text ?? ""
                    color: Theme.fg
                    font: Theme.body
                  }
                }

                ExpanderArrow {
                  x: parent.width - width - 8
                  anchors.verticalCenter: parent.verticalCenter
                  visible: entry.modelData?.hasChildren ?? false
                  rotation: -90
                }

                HoverHandler {
                  id: entryHover

                  onHoveredChanged: {
                    if (!hovered || !entry.modelData || entry.modelData.isSeparator) return;
                    if (!entry.modelData.enabled || !entry.modelData.hasChildren) {
                      root.apply(card.index, "");
                      return;
                    }
                    root.pending = { level: card.index, label: entry.modelData.text };
                    hoverDelay.restart();
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: entry.modelData?.enabled ?? false
                  onClicked: {
                    if (!entry.modelData) return;
                    if (entry.modelData.hasChildren) {
                      root.apply(card.index, entry.opened ? "" : entry.modelData.text);
                    } else {
                      entry.modelData.triggered();
                      Panels.close();
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
}
