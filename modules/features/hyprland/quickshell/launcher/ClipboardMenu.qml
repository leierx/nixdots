import Quickshell
import qs.common
import "search.js" as Search

// cliphist's history, newest first; the picked entry goes back on the
// clipboard, and Shift+Delete removes it. Images show as thumbnails, decoded
// into the cache as the picker opens.
MenuWindow {
  id: root

  property var entries: []
  // Thumbnails, named by cliphist id.
  readonly property string thumbnails: Quickshell.cachePath("clipboard")

  cardWidth: 960
  fullHeight: list.fullHeight

  // Lists the history after decoding the images it has no thumbnail of yet,
  // and drops the thumbnails of entries that are gone.
  MenuCommand {
    command: ["sh", "-c", `
      mkdir -p "$1" && cd "$1" || exit
      list=$(cliphist list) || exit
      printf '%s\\n' "$list" | while IFS="$(printf '\\t')" read -r id text; do
        case $text in "[[ binary data "*) [ -s "$id" ] || cliphist decode "$id" > "$id" ;; esac
      done
      for file in *; do
        [ -e "$file" ] || continue
        printf '%s\\n' "$list" | grep -q "^$file$(printf '\\t')" || rm -f "$file"
      done
      printf '%s\\n' "$list"
    `, "sh", root.thumbnails]
    onDone: output => {
      root.entries = output.split("\n").filter(line => line !== "").map(line => {
        const tab = line.indexOf("\t");
        return { id: line.slice(0, tab), text: line.slice(tab + 1), line: line };
      });
    }
  }

  MenuList {
    id: list

    placeholder: "Search clipboard…"
    maxRows: 12
    results: root.search(list.query)
    onActivated: row => {
      Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", row.id]);
      Panels.close();
    }
    onRemoved: row => {
      Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", row.line]);
      root.entries = root.entries.filter(entry => entry.id !== row.id);
    }
  }

  function search(query) {
    const rows = [];
    root.entries.forEach((entry, index) => {
      // "[[ binary data 140 KiB png 1920x1080 ]]"
      const image = /^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/.exec(entry.text);
      const row = image ? {
        title: "Image",
        subtitle: `${image[3]}×${image[4]} ${image[2].toUpperCase()}, ${image[1]}`,
        thumbnail: `file://${root.thumbnails}/${entry.id}`,
      } : {
        title: entry.text,
      };
      const score = Search.scoreFields(query, [[1.0, row.title], [1.0, row.subtitle]]);
      if (score >= 0) {
        rows.push(Object.assign(row, { key: entry.id, id: entry.id, line: entry.line, score: score, index: index }));
      }
    });
    rows.sort((a, b) => b.score - a.score || a.index - b.index);
    return rows;
  }
}
