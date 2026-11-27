import QtQuick
import Quickshell
import qs.common
import qs.nix

LauncherMode {
  id: root

  // For Terminal=true entries, whose command has no terminal of its own.
  readonly property list<string> terminal: ["wezterm", "start", "--"]

  name: "apps"
  title: "Applications"
  glyph: Symbols.search
  placeholder: "Search applications…"
  nothing: "No Applications"
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
    const id = row.entry.id;
    Detached.run(row.entry.runInTerminal ? [...root.terminal, ...row.entry.command] : row.entry.command, row.entry.workingDirectory);
    Panels.close();
    // New ranks search again: a turn later the launch is on its way and the closed window gone.
    Qt.callLater(() => AppUsage.launched(id));
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
