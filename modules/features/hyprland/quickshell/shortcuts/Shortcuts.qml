pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

Scope {
  id: root

  readonly property bool open: Panels.active === "shortcuts"
  property var groups: []

  function chord(modmask: int, key: string): var {
    const mods = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]].filter(([bit]) => modmask & bit).map(([, name]) => name);
    const names = { Return: "Enter", ESCAPE: "Esc", Escape: "Esc", plus: "+", space: "Space", "mouse:272": "Left click", "mouse:273": "Right click", "mouse:274": "Middle click" };
    return [...mods, names[key] ?? (key.length === 1 ? key.toUpperCase() : key)];
  }

  // Media keys are left out: they are labelled on the keyboard.
  function group(binds: var): var {
    // No submaps: the config has none.
    const main = binds.filter(bind => bind.has_description && !bind.key.startsWith("XF86") && bind.submap === "");

    const rows = [];
    for (const bind of main) {
      const numbered = /^(.*\S)\s+(\d+)$/.exec(bind.description);
      const row = numbered && numbered[2] === bind.key ? rows.find(other => other.prefix === numbered[1] && other.modmask === bind.modmask) : null;
      if (row) {
        row.last = bind.key;
        row.keys = [[...root.chord(bind.modmask, row.first).slice(0, -1), `${row.first}…${row.last}`]];
      } else {
        rows.push({
          title: numbered && numbered[2] === bind.key ? numbered[1] : bind.description,
          prefix: numbered ? numbered[1] : null,
          first: bind.key,
          last: bind.key,
          modmask: bind.modmask,
          mouse: bind.key.startsWith("mouse:"),
          keys: [root.chord(bind.modmask, bind.key)],
        });
      }
    }

    // Directions fold as numbers do: "Focus left" to "Focus right" become one row, its keys in Vim's order.
    const order = ["left", "down", "up", "right"];
    const folded = [];
    for (const row of rows) {
      const direction = row.mouse ? null : /^(.*?)\s*\b(left|down|up|right)\b\s*(.*)$/i.exec(row.title);
      if (!direction) {
        folded.push(row);
        continue;
      }
      const base = `${direction[1]} ${direction[3]}`.trim();
      let into = folded.find(other => other.base === base && other.modmask === row.modmask);
      if (!into) {
        into = Object.assign({}, row, { base, single: row.title, ways: [] });
        folded.push(into);
      }
      into.ways.push({ at: order.indexOf(direction[2].toLowerCase()), key: row.first });
      into.ways.sort((a, b) => a.at - b.at);
      into.title = into.ways.length > 1 ? base : into.single;
      into.keys = [[...root.chord(row.modmask, row.first).slice(0, -1), into.ways.map(way => root.chord(0, way.key)[0]).join(" ")]];
    }

    const titled = [
      { title: "General", rows: [] },
      { title: "Windows", rows: [] },
      { title: "Workspaces", rows: [] },
      { title: "Mouse", rows: [] },
    ];
    for (const row of folded) {
      const index = row.mouse ? 3 : /workspace/i.test(row.title) ? 2 : /window|focus|fullscreen|maximi|float/i.test(row.title) ? 1 : 0;
      titled[index].rows.push(row);
    }
    return titled.filter(group => group.rows.length > 0);
  }

  onOpenChanged: if (open) binds.running = true

  GlobalShortcut {
    name: "shortcuts"
    description: "Keyboard shortcuts"
    onPressed: Panels.toggle("shortcuts")
  }

  Command {
    id: binds

    command: ["hyprctl", "binds", "-j"]
    // Someone waits on it with nothing shown.
    timeout: 5000
    onDone: output => {
      let groups;
      try {
        groups = root.group(JSON.parse(output));
      } catch (error) {
        binds.fail(String(error));
        return;
      }
      // Nothing to show would leave the panel open with no window.
      if (groups.length === 0) binds.fail("Hyprland reported no described binds");
      else root.groups = groups;
    }
  }

  // Once the binds are in, so a first open never shows a card with only its title.
  LazyLoader {
    active: root.open && root.groups.length > 0

    ShortcutsWindow {
      groups: root.groups
    }
  }
}
