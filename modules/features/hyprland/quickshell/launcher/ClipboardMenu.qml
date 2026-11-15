import Quickshell
import qs.common
import qs.nix
import "search.js" as Search

// cliphist's history, newest first; the picked entry goes back on the clipboard.
MenuWindow {
  id: root

  property var entries: []

  cardWidth: Theme.px(960)
  fullHeight: list.fullHeight

  MenuCommand {
    command: [Bin.cliphist, "list"]
    onDone: output => {
      root.entries = output.split("\n").filter(line => line !== "").map(line => {
        const tab = line.indexOf("\t");
        return { id: line.slice(0, tab), text: line.slice(tab + 1) };
      });
    }
  }

  MenuList {
    id: list

    placeholder: "Search clipboard…"
    maxRows: 12
    results: root.search(list.query)
    onActivated: row => {
      Quickshell.execDetached([Bin.cliphistCopy, row.id]);
      Panels.close();
    }
  }

  function search(query) {
    const rows = [];
    root.entries.forEach((entry, index) => {
      const score = Search.score(query, entry.text);
      if (score >= 0) {
        rows.push({ score: score, index: index, title: entry.text, id: entry.id });
      }
    });
    rows.sort((a, b) => b.score - a.score || a.index - b.index);
    return rows;
  }
}
