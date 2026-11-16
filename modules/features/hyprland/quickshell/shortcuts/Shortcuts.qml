import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common

// Hyprland's own binds with their descriptions, read afresh on every open.
Scope {
  id: root

  readonly property bool open: Panels.active === "shortcuts"
  property var groups: []

  function chord(modmask: int, key: string): var {
    const mods = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]].filter(([bit]) => modmask & bit).map(([, name]) => name);
    const names = { Return: "Enter", ESCAPE: "Esc", Escape: "Esc", question: "?", plus: "+", space: "Space", "mouse:272": "Left click", "mouse:273": "Right click", "mouse:274": "Middle click" };
    return [...mods, names[key] ?? (key.length === 1 ? key.toUpperCase() : key)];
  }

  // Media keys are left out: they are labelled on the keyboard.
  function group(binds: var): var {
    const described = binds.filter(bind => bind.has_description && !bind.key.startsWith("XF86"));
    const main = described.filter(bind => bind.submap === "");
    const normalise = text => text.toLowerCase().replace(/[^a-z]/g, "");

    // A submap is entered by the bind its name begins: "system_control" by "System controls".
    const submaps = [...new Set(described.map(bind => bind.submap).filter(name => name !== ""))].map(name => {
      const entry = main.find(bind => normalise(bind.description).startsWith(normalise(name)));
      return { name, entry };
    });
    const entries = submaps.map(submap => submap.entry).filter(entry => entry);

    // Numbered binds, "Focus workspace 1" to "6", become one row.
    const rows = [];
    for (const bind of main.filter(bind => !entries.includes(bind))) {
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

    const titled = [
      { title: "General", rows: [] },
      { title: "Windows", rows: [] },
      { title: "Workspaces", rows: [] },
      { title: "Mouse", rows: [] },
    ];
    for (const row of rows) {
      const index = row.mouse ? 3 : /workspace/i.test(row.title) ? 2 : /window|focus|fullscreen|maximi|float/i.test(row.title) ? 1 : 0;
      titled[index].rows.push(row);
    }
    for (const submap of submaps) {
      const prefix = submap.entry ? [root.chord(submap.entry.modmask, submap.entry.key)] : [];
      titled.push({
        title: submap.entry?.description ?? submap.name.replace(/_/g, " "),
        rows: described.filter(bind => bind.submap === submap.name).map(bind => ({ title: bind.description, keys: [...prefix, root.chord(bind.modmask, bind.key)] })),
      });
    }
    return titled.filter(group => group.rows.length > 0);
  }

  onOpenChanged: if (open) binds.running = true

  GlobalShortcut {
    name: "shortcuts"
    description: "Keyboard shortcuts"
    onPressed: Panels.toggle("shortcuts")
  }

  Process {
    id: binds

    command: ["hyprctl", "binds", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.groups = root.group(JSON.parse(text));
        } catch (error) {
          console.warn(`Shortcuts: reading Hyprland's binds failed: ${error}`);
        }
      }
    }
  }

  LazyLoader {
    active: root.open

    ShortcutsWindow {
      groups: root.groups
    }
  }
}
