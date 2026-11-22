import QtQuick

// What floats: Shell's popover surface, its 1 px edge and its shadow.
Rectangle {
  id: root

  property alias shadow: shade

  radius: Theme.popoverRadius
  color: Theme.popoverBg
  border.width: 1
  border.color: Theme.popoverBorder

  // A step back first, a submenu shut say: true when it took one, so Escape closes the panel only once there is none.
  property var back: null
  Keys.onEscapePressed: if (!(root.back?.() ?? false)) Panels.close()
  // A control of its own the keyboard was on can go (a row rebuilt, a menu shut): the card takes it back, so Escape and Tab still work.
  property Item lastFocus: null
  Window.onActiveFocusItemChanged: {
    const item = Window.activeFocusItem;
    const lost = !item || item === Window.contentItem;
    if (lost && root.visible && root.lastFocus !== null) root.forceActiveFocus();
    let inside = false;
    for (let at = item; at && !inside; at = at.parent) inside = at === root;
    root.lastFocus = inside && item !== root ? item : null;
  }
  // Tab goes on as Qt takes it; the arrows step through the same order, where nothing nearer takes them.
  Keys.onPressed: event => {
    const steps = { [Qt.Key_Down]: true, [Qt.Key_Right]: true, [Qt.Key_Up]: false, [Qt.Key_Left]: false };
    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      Panels.keyboard = true;
      event.accepted = false;
    } else if (event.key in steps) {
      const from = root.Window.activeFocusItem ?? root;
      // A text field passes on Left at its start and Right at its end, which are still its own.
      if (from instanceof TextInput && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) return;
      const next = from.nextItemInFocusChain(steps[event.key]);
      if (next) next.forceActiveFocus(Qt.TabFocusReason);
      Panels.keyboard = true;
      event.accepted = true;
    }
  }

  Shadow {
    id: shade
  }
}
