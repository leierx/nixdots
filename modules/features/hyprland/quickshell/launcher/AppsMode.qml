import QtQuick
import Quickshell
import qs.common

LauncherMode {
  id: root

  // For Terminal=true entries, whose command has no terminal of its own.
  readonly property list<string> terminal: ["wezterm", "start", "--"]

  name: "apps"
  title: "Applications"
  // Material Symbols' search
  glyph: "M380-320q-109 0-184.5-75.5T120-580q0-109 75.5-184.5T380-840q109 0 184.5 75.5T640-580q0 44-14 83t-38 69l224 224q11 11 11 28t-11 28q-11 11-28 11t-28-11L532-372q-30 24-69 38t-83 14Zm0-80q75 0 127.5-52.5T560-580q0-75-52.5-127.5T380-760q-75 0-127.5 52.5T200-580q0 75 52.5 127.5T380-400Z"
  placeholder: "Search applications…"
  fields: row => [
    [1.0, row.entry.name, true],
    [0.8, row.entry.genericName],
    [0.6, row.entry.keywords.join(" ")],
    [0.6, (row.entry.command[0] ?? "").split("/").pop()],
    [0.4, row.entry.categories.join(" ")],
  ]
  rows: DesktopEntries.applications.values
    .map(entry => ({
      key: entry.id,
      title: entry.name,
      icon: Quickshell.iconPath(entry.icon, "application-x-executable"),
      // Under half the step between kinds of match in search.js, so use only orders equal matches.
      boost: 50 * AppUsage.use(entry.id),
      entry: entry,
    }))
    .sort((a, b) => a.title.localeCompare(b.title))

  onActivated: row => {
    AppUsage.launched(row.entry.id);
    Detached.run(row.entry.runInTerminal ? [...root.terminal, ...row.entry.command] : row.entry.command, row.entry.workingDirectory);
    Panels.close();
  }

  // On a first open the entries arrived one by one, each rebuilding the list.
  Component.onCompleted: {
    DesktopEntries.applications.values;
    AppUsage.week;
    Quickshell.hasThemeIcon("application-x-executable");
  }

  // An icon Papirus lacks costs thousands of failed stats, enough to miss the first keys typed.
  Connections {
    target: DesktopEntries.applications

    function onValuesChanged() {
      Qt.callLater(warmIcons);
    }

    // Later, so a scan's entries, arriving one by one, are looked up once.
    function warmIcons() {
      for (const entry of DesktopEntries.applications.values) Quickshell.hasThemeIcon(entry.icon);
    }
  }
}
