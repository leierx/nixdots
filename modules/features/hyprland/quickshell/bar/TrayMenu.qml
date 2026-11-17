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
  property list<QsMenuEntry> path: []
  // An entry the app has since dropped turns null, and takes the submenus from it on.
  readonly property var levels: {
    const dropped = root.path.indexOf(null);
    return [root.menu, ...(dropped < 0 ? root.path : root.path.slice(0, dropped))];
  }
  // Cards register here, as the window's input region is theirs alone.
  property list<Item> cards: []
  // A moment's delay, so passing over rows opens nothing.
  property var pending: null
  readonly property int padding: 6

  function apply(level: int, entry: var): void {
    root.pending = null;
    root.path = [...root.path.slice(0, level), ...(entry?.hasChildren ? [entry] : [])];
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
    onTriggered: if (root.pending) root.apply(root.pending.level, root.pending.entry)
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

      model: ScriptModel {
        values: root.levels
      }

      Card {
        id: card

        required property QsMenuHandle modelData
        required property int index

        readonly property Region region: Region {
          item: card
        }
        readonly property Item parentCard: index > 0 ? levels.itemAt(index - 1) : null
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
        readonly property real openerY: parentCard?.rowY(modelData) ?? 0

        function rowY(entry: var): real {
          const row = rowsRepeater.itemAt(entries.indexOf(entry));
          return row ? row.mapToItem(card, 0, 0).y : root.padding;
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

        Component.onCompleted: root.cards = [...root.cards, card]
        Component.onDestruction: root.cards = root.cards.filter(other => other !== card)
        // A list does not notice its entry dropped, so the submenu says so itself.
        onModelDataChanged: if (modelData === null && index > 0) root.apply(index - 1, null)

        QsMenuOpener {
          id: opener

          menu: card.modelData
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

            model: ScriptModel {
              values: card.entries
            }

            Item {
              id: entry

              required property QsMenuEntry modelData
              readonly property bool opened: root.path[card.index] === modelData
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
                    visible: entry.modelData?.buttonType !== QsMenuButtonType.None

                    Shape {
                      anchors.fill: parent
                      visible: entry.modelData?.buttonType === QsMenuButtonType.CheckBox && entry.modelData?.checkState === Qt.Checked
                      preferredRendererType: Shape.CurveRenderer

                      ShapePath {
                        strokeColor: Theme.fg
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathPolyline {
                          path: [Qt.point(3, 8.5), Qt.point(6.5, 12), Qt.point(13, 4.5)]
                        }
                      }
                    }

                    Rectangle {
                      anchors.centerIn: parent
                      width: 6
                      height: 6
                      radius: 3
                      visible: entry.modelData?.buttonType === QsMenuButtonType.RadioButton && entry.modelData?.checkState === Qt.Checked
                      color: Theme.fg
                    }
                  }

                  IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 16
                    visible: !!entry.modelData?.icon
                    source: entry.modelData?.icon ?? ""
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
                      root.apply(card.index, null);
                      return;
                    }
                    root.pending = { level: card.index, entry: entry.modelData };
                    hoverDelay.restart();
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: entry.modelData?.enabled ?? false
                  onClicked: {
                    if (!entry.modelData) return;
                    if (entry.modelData.hasChildren) {
                      root.apply(card.index, entry.opened ? null : entry.modelData);
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
