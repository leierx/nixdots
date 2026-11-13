import Quickshell
import qs.components
import qs.services
import "search.js" as Search

// The application launcher, like rofi's drun: desktop entries matched on the
// fields the rofi config matches (name, generic name, keywords, executable and
// categories), best match first.
MenuWindow {
  id: root

  // Entries with Terminal=true are run inside this, since
  // DesktopEntry.execute() would start them without one.
  property list<string> terminal: ["wezterm", "start", "--"]

  fullHeight: list.fullHeight

  MenuList {
    id: list

    placeholder: "Search applications…"
    results: root.search(list.query)
    onActivated: row => {
      root.launch(row.entry);
      MenuState.close();
    }
  }

  function search(query) {
    const rows = [];
    for (const entry of DesktopEntries.applications.values) {
      const score = Search.scoreFields(query, [
        [1.0, entry.name],
        [0.8, entry.genericName],
        [0.6, entry.keywords.join(" ")],
        [0.6, (entry.command[0] ?? "").split("/").pop()],
        [0.4, entry.categories.join(" ")],
      ]);
      if (score >= 0) {
        rows.push({
          score: score,
          title: entry.name,
          subtitle: entry.genericName,
          icon: Quickshell.iconPath(entry.icon, "application-x-executable"),
          entry: entry,
        });
      }
    }

    // Equal scores, which is all of them before anything is typed, sort by name.
    rows.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
    return rows;
  }

  function launch(entry) {
    if (entry.runInTerminal) {
      Quickshell.execDetached([...root.terminal, ...entry.command]);
    } else {
      entry.execute();
    }
  }
}
