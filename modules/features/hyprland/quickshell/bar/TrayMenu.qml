pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
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
  // The labels of the open submenus rather than their entries: apps rebuild a menu whole, every entry new, as Electron ones do on each update.
  property var path: []
  // Cards register here, as the window's input region is theirs alone.
  property list<Item> cards: []
  // A moment's delay, so passing over rows opens nothing.
  property var pending: null
  // The keyboard's row in the deepest open card.
  property int row: -1
  // The card the row is in: the deepest, but for the pointer on the opener of a submenu still open.
  property int rowLevel: 0
  // Keys have driven it since the pointer was last on it, so it stays without the pointer.
  property bool keyed: false
  // The next card to open takes its first row once its entries come.
  property bool pickFirst: false
  readonly property int padding: 6

  // The pointer gone from it, the app's menu gone, or Escape: the tray closes it.
  signal dismissed

  // libadwaita's check button: an outlined box (a ring for a radio), filled with the accent once checked.
  component CheckIndicator: Rectangle {
    id: indicator

    property bool radio: false
    property int checkState: Qt.Unchecked
    readonly property bool on: checkState !== Qt.Unchecked

    width: 14
    height: 14
    radius: radio ? width / 2 : 4
    color: on ? Theme.accentBg : "transparent"
    border.width: on ? 0 : 2
    border.color: Theme.checkBorder

    Rectangle {
      anchors.centerIn: parent
      width: 6
      height: 6
      radius: width / 2
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
    const opened = label !== "" && label !== (root.path[level] ?? "");
    const next = [...root.path.slice(0, level), ...(label ? [label] : [])];
    const shut = root.path[next.length] ?? "";
    root.path = next;
    // The keyboard starts afresh in a submenu just opened, or stays on the row whose submenu just shut.
    if (opened) root.select(-1);
    else if (shut) root.select((root.level(next.length)?.entries ?? []).findIndex(entry => entry.hasChildren && entry.text === shut));
  }

  function select(row: int): void {
    root.rowLevel = root.path.length;
    root.row = row;
  }

  function selectable(entry: var): bool {
    return !!entry && !entry.isSeparator && entry.enabled;
  }

  // The next row the keyboard can land on, going round.
  function step(entries: var, from: int, by: int): int {
    const start = from < 0 && by < 0 ? entries.length : from;
    for (let n = 1; n <= entries.length; n++) {
      const at = (((start + by * n) % entries.length) + entries.length) % entries.length;
      if (root.selectable(entries[at])) return at;
    }
    return -1;
  }

  // A key while the menu is up; false for one it leaves alone.
  function key(event: var): bool {
    const depth = root.path.length;
    const entries = root.level(depth)?.entries ?? [];
    const entry = root.level(root.rowLevel)?.entries[root.row] ?? null;
    // A row in a card above, or past the end of a menu the app shortened, steps from the start.
    const from = root.rowLevel === depth && root.row < entries.length ? root.row : -1;
    switch (event.key) {
    case Qt.Key_Down:
    case Qt.Key_Up:
      root.select(root.step(entries, from, event.key === Qt.Key_Down ? 1 : -1));
      return true;
    case Qt.Key_Home:
      root.select(root.step(entries, -1, 1));
      return true;
    case Qt.Key_End:
      root.select(root.step(entries, -1, -1));
      return true;
    case Qt.Key_Right:
    case Qt.Key_Return:
    case Qt.Key_Enter:
    case Qt.Key_Space:
      if (!root.selectable(entry)) return true;
      if (entry.hasChildren) {
        const at = root.rowLevel;
        root.pickFirst = true;
        root.apply(at, entry.text);
        const opened = root.level(at + 1)?.entries ?? [];
        root.select(root.step(opened, -1, 1));
        if (opened.length > 0) root.pickFirst = false;
      } else if (event.key !== Qt.Key_Right) {
        entry.triggered();
        Panels.close();
      }
      return true;
    case Qt.Key_Left:
      if (depth > 0) root.apply(depth - 1, "");
      return true;
    case Qt.Key_Escape:
      // A submenu first, as every menu goes back.
      if (depth > 0) root.apply(depth - 1, "");
      else root.dismissed();
      return true;
    case Qt.Key_Menu:
      root.dismissed();
      return true;
    case Qt.Key_Tab:
    case Qt.Key_Backtab:
      return true;
    }
    if (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier) {
      root.dismissed();
      return true;
    }
    return false;
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
  // The keyboard while it is up: the arrows, Return and Escape walk it. Exclusive only until it has it, as an Overlay, so a window clicked elsewhere gets it.
  property bool focused: false
  WlrLayershell.keyboardFocus: focused ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

  // Hyprland closes it with its monitor.
  onClosed: if (Panels.active === root.name) Panels.close()
  // A new menu from the app shares no entries with the old one.
  onMenuChanged: {
    root.path = [];
    if (root.menu === null) root.dismissed();
  }

  Timer {
    id: hoverDelay

    interval: 150
    onTriggered: if (root.pending) root.apply(root.pending.level, root.pending.label)
  }

  Timer {
    running: !inside.hovered && !root.held && !root.keyed
    interval: 100
    onTriggered: root.dismissed()
  }

  // Only the cards take input, so this is hovered exactly while the pointer is on one; hover reaches ancestors, not siblings beneath.
  Item {
    anchors.fill: parent
    focus: true
    Window.onActiveChanged: {
      if (Window.active) root.focused = true;
      else if (root.focused) root.dismissed();
    }
    Keys.onPressed: event => {
      event.accepted = root.key(event);
      if (event.accepted) root.keyed = true;
    }

    HoverHandler {
      id: inside

      onHoveredChanged: if (hovered) root.keyed = false
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
        // How far its rows are scrolled, for the probe.
        readonly property real offset: scroller.contentY

        readonly property Region region: Region {
          item: card
        }
        readonly property var parentCard: index > 0 ? root.level(index - 1) : null
        readonly property int direction: {
          const way = parentCard?.direction ?? (root.anchor.x + width + Theme.rise <= root.width ? 1 : -1);
          const fits = way > 0 ? x + 2 * width + Theme.rise <= root.width : x - width - Theme.rise >= 0;
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
          return root.padding + (row?.y ?? 0) - scroller.contentY;
        }

        // The keyboard's row kept in view, in a card cut to the screen.
        function reveal(index: int): void {
          const row = rowsRepeater.itemAt(index);
          if (!row) return;
          if (row.y < scroller.contentY) scroller.contentY = row.y;
          else if (row.y + row.height > scroller.contentY + scroller.height) scroller.contentY = row.y + row.height - scroller.height;
        }

        x: {
          if (!parentCard) return root.anchor.x + width + Theme.rise <= root.width ? root.anchor.x : Math.max(Theme.rise, root.anchor.x - width);
          const beside = parentCard.direction > 0 ? parentCard.x + parentCard.width - 4 : parentCard.x - width + 4;
          return Math.max(Theme.rise, Math.min(beside, root.width - width - Theme.rise));
        }
        y: Math.max(Theme.rise, Math.min((parentCard ? parentCard.y + openerY - root.padding : root.anchor.y), root.height - height - Theme.rise))
        // Shell's .popup-menu: at least 15 em; at most what the screen leaves, the rest eliding and scrolling.
        width: Math.min(Math.max(Math.round(15 * Theme.em), rows.implicitWidth) + root.padding * 2, Math.round(34 * Theme.em), root.width - 2 * Theme.rise)
        height: Math.min(rows.implicitHeight + root.padding * 2, root.height - 2 * Theme.rise)
        radius: Theme.popoverRadius

        Component.onCompleted: {
          root.cards = [...root.cards, card];
          if (index > 0 && !handle) Qt.callLater(root.prune);
        }
        Component.onDestruction: root.cards = root.cards.filter(other => other !== card)
        // Later, as changing the levels from a binding they feed loops.
        onHandleChanged: if (handle === null && index > 0) Qt.callLater(root.prune)
        onEntriesChanged: {
          if (root.pickFirst && card.index === root.path.length && entries.length > 0) {
            root.pickFirst = false;
            root.select(root.step(entries, -1, 1));
          }
        }

        Connections {
          target: root

          function onRowChanged(): void {
            if (card.index === root.path.length && root.row >= 0) card.reveal(root.row);
          }
        }

        QsMenuOpener {
          id: opener

          menu: card.handle
        }

        Flickable {
          id: scroller

          QQC.ScrollIndicator.vertical: ScrollBar {}
          anchors {
            fill: parent
            margins: root.padding
          }
          contentHeight: rows.implicitHeight
          interactive: contentHeight > height
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          ColumnLayout {
            id: rows

            width: scroller.width
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
                required property int index
                readonly property bool opened: (modelData?.hasChildren ?? false) && root.path[card.index] === modelData.text
                readonly property bool picked: root.keyed && card.index === root.path.length && root.row === index
                // Room for the arrows, which point right whichever side the submenu opens, as GTK's do.
                readonly property int arrowSpace: card.cascades ? 24 : 0
                readonly property bool checkable: (modelData?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None
                readonly property bool iconed: !!modelData?.icon
                // What comes before the label, which elides in a card cut to the screen.
                readonly property real lead: (checkable ? 16 + content.spacing : 0) + (iconed ? 16 + content.spacing : 0)

                Layout.fillWidth: true
                implicitWidth: modelData?.isSeparator ? 0 : lead + label.implicitWidth + 2 * Theme.padding + arrowSpace
                implicitHeight: modelData?.isSeparator ? 13 : Theme.menuRowHeight

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: 1
                  visible: entry.modelData?.isSeparator ?? false
                  color: Theme.separator
                }

                Rectangle {
                  anchors.fill: parent
                  visible: !entry.modelData?.isSeparator
                  radius: Theme.menuItemRadius
                  // The keyboard's row snaps, as keyboard selection never animates; hover and a press ease over it.
                  color: entry.modelData?.enabled && entry.picked ? Theme.selectedBg : "transparent"

                  Rectangle {
                    anchors.fill: parent
                    radius: Theme.menuItemRadius
                    color: {
                      if (!entry.modelData?.enabled) return "transparent";
                      if (press.pressed) return Theme.menuActiveBg;
                      return (entryHover.hovered || entry.opened) && !entry.picked ? Theme.menuHoverBg : "transparent";
                    }

                    Behavior on color {
                      ColorAnimation {
                        duration: Theme.quickTime
                        easing.type: Easing.OutQuad
                      }
                    }
                  }

                  Row {
                    id: content

                    x: Theme.padding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.basePadding
                    opacity: entry.modelData?.enabled ? 1 : 0.5

                    Item {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 16
                      height: 16
                      visible: entry.checkable

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
                      visible: entry.iconed

                      IconImage {
                        anchors.fill: parent
                        source: entry.modelData ? entry.modelData.icon : ""
                      }
                    }

                    Text {
                      id: label

                      anchors.verticalCenter: parent.verticalCenter
                      width: Math.min(implicitWidth, entry.width - entry.lead - 2 * Theme.padding - entry.arrowSpace)
                      text: entry.modelData?.text ?? ""
                      // An app's own words, never markup.
                      textFormat: Text.PlainText
                      maximumLineCount: 1
                      elide: Text.ElideRight
                      color: Theme.fg
                      font: Theme.body
                    }
                  }

                  ExpanderArrow {
                    x: parent.width - width - Theme.basePadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData?.hasChildren ?? false
                    pointing: "right"
                  }

                  HoverHandler {
                    id: entryHover

                    onHoveredChanged: {
                      if (!hovered || !entry.modelData || entry.modelData.isSeparator) return;
                      if (!entry.modelData.enabled || !entry.modelData.hasChildren) root.apply(card.index, "");
                      root.rowLevel = card.index;
                      root.row = entry.modelData.enabled ? entry.index : -1;
                      if (!entry.modelData.enabled || !entry.modelData.hasChildren) return;
                      root.pending = { level: card.index, label: entry.modelData.text };
                      hoverDelay.restart();
                    }
                  }

                  MouseArea {
                    id: press

                    anchors.fill: parent
                    enabled: entry.modelData?.enabled ?? false
                    // Disabled, it would still set a hand.
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
}
