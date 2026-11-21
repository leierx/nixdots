import QtQuick

Rectangle {
  id: root

  radius: Theme.windowRadius
  color: Theme.bg
  border.width: 1
  border.color: Theme.outline

  Keys.onEscapePressed: Panels.close()
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
      const next = from.nextItemInFocusChain(steps[event.key]);
      if (next) next.forceActiveFocus(Qt.TabFocusReason);
      Panels.keyboard = true;
      event.accepted = true;
    }
  }

  Shadow {}
}
