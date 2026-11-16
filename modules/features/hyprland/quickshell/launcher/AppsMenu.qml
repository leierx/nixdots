import Quickshell
import qs.common
import "search.js" as Search

MenuWindow {
  id: root

  // For Terminal=true entries, whose command has no terminal of its own.
  readonly property list<string> terminal: ["wezterm", "start", "--"]

  fullHeight: list.fullHeight

  MenuList {
    id: list

    placeholder: "Search applications…"
    results: root.search(list.query)
    onActivated: row => {
      root.launch(row.entry);
      Panels.close();
    }
  }

  function search(query) {
    const rows = [];
    for (const entry of DesktopEntries.applications.values) {
      const score = Search.scoreFields(query, [
        [1.0, entry.name, true],
        [0.8, entry.genericName],
        [0.6, entry.keywords.join(" ")],
        [0.6, (entry.command[0] ?? "").split("/").pop()],
        [0.4, entry.categories.join(" ")],
      ]);
      if (score >= 0) {
        rows.push({
          key: entry.id,
          // Under half the step between kinds of match in search.js, so use only orders equal matches.
          score: score + 50 * AppUsage.use(entry.id),
          title: entry.name,
          subtitle: entry.genericName,
          icon: Quickshell.iconPath(entry.icon, "application-x-executable"),
          entry: entry,
        });
      }
    }

    rows.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
    return rows;
  }

  // Each app gets its own scope, so restarting the shell's service leaves it running.
  function launch(entry) {
    AppUsage.launched(entry.id);
    const command = entry.runInTerminal ? [...root.terminal, ...entry.command] : entry.command;
    Quickshell.execDetached({
      command: ["systemd-run", "--user", "--scope", "--quiet", ...command],
      workingDirectory: entry.workingDirectory,
      // The shell's own scale, from shell.qml, is not the app's.
      environment: ({ QT_SCALE_FACTOR: null }),
    });
  }
}
