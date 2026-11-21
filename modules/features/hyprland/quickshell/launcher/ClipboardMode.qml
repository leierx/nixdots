import QtQuick
import Quickshell
import qs.common

LauncherMode {
  id: root

  property var entries: []
  property var pictures: ({})
  property var stats: ({})
  readonly property string cache: Quickshell.cachePath("clipboard")

  function plural(count: int, word: string): string {
    return `${count} ${word}${count === 1 ? "" : "s"}`;
  }

  name: "clipboard"
  title: "Clipboard"
  glyph: Symbols.clipboard
  placeholder: "Search clipboard…"
  nothing: "Nothing copied yet"
  wide: true
  removable: true
  rows: root.entries.map(entry => {
    // "[[ binary data 140 KiB png 1920x1080 ]]"
    const image = /^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/.exec(entry.text);
    const stats = root.stats[entry.id];
    return Object.assign(image ? {
      title: "Image",
      subtitle: `${image[3]}×${image[4]} ${image[2].toUpperCase()}, ${image[1]}`,
      glyph: Symbols.image,
      thumbnail: root.pictures[entry.id] ? `file://${root.cache}/${entry.id}` : "",
      size: { width: Number(image[3]), height: Number(image[4]) },
    } : {
      title: entry.text,
      subtitle: stats ? `${root.plural(stats[1], "character")}, ${root.plural(stats[0], "line")}` : "",
      glyph: /^https?:\/\/\S+$/.test(entry.text)
        ? Symbols.link
        : Symbols.notes,
    }, { key: entry.id, id: entry.id, line: entry.line });
  })
  fields: row => [[1.0, row.title], [1.0, row.subtitle]]

  // At the start too, so pictures from a history wiped at login leave the cache.
  Component.onCompleted: cacheCommand.running = true
  onOpened: listCommand.running = true
  onOpenChanged: if (!open) entries = []
  onActivated: row => {
    // wl-copy stays behind to serve the clip.
    Detached.run(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", row.id], "");
    Panels.close();
  }
  onRemoved: row => {
    Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", row.line]);
    root.entries = root.entries.filter(entry => entry.id !== row.id);
  }

  // The rows show at once; what needs a clip decoded follows from the cache.
  Command {
    id: listCommand

    command: ["cliphist", "list"]
    onDone: output => {
      root.entries = output.split("\n").filter(line => line !== "").map(line => {
        const tab = line.indexOf("\t");
        return { id: line.slice(0, tab), text: line.slice(tab + 1), line: line };
      });
      cacheCommand.running = true;
    }
  }

  // Thumbnails and counts are made once per clip. A picture past 64 MiB or 50 megapixels gets none: decoding it would cost more than it shows.
  Command {
    id: cacheCommand

    name: "cliphist"
    command: ["sh", "-c", `
      set -f
      mkdir -p "$1" && cd "$1" || exit
      list=$(cliphist list) || exit
      tab=$(printf '\\t')
      printf '%s\\n' "$list" | while IFS="$tab" read -r id text; do
        case $text in
          "[[ binary data "*)
            set -- $text
            case $5 in GiB) continue ;; MiB) [ "\${4%.*}" -lt 64 ] || continue ;; esac
            width=\${7%x*} height=\${7#*x}
            case $width$height in "" | *[!0-9]*) continue ;; esac
            [ $((width * height)) -le 50000000 ] || continue
            [ -s "$id" ] || { cliphist decode "$id" > "$id.part" && mv "$id.part" "$id"; }
            ;;
          *)
            [ -s "$id.stats" ] || cliphist decode "$id" | awk '{ count += length($0) + 1 } END { print NR, count - (NR > 0) }' > "$id.stats"
            ;;
        esac
      done
      set +f
      ids=" $(printf '%s\\n' "$list" | cut -f1 | tr '\\n' ' ')"
      for file in *; do
        case $ids in *" \${file%.stats} "*) ;; *) rm -f "$file" ;; esac
      done
      for file in *; do
        case $file in *.stats) ;; *) [ -e "$file" ] && printf '%s\\n' "$file" ;; esac
      done
      echo --
      set -- *.stats
      [ -e "$1" ] && awk '{ id = FILENAME; sub(/\\.stats$/, "", id); print id, $0 }' "$@"
      true
    `, "sh", root.cache]
    onDone: output => {
      const [pictures, stats] = output.split("--\n");
      const decoded = {};
      for (const id of pictures.split("\n").filter(id => id !== "")) decoded[id] = true;
      root.pictures = decoded;
      const counts = {};
      for (const line of (stats ?? "").split("\n").filter(line => line !== "")) {
        const [id, lines, characters] = line.split(" ");
        counts[id] = [Number(lines), Number(characters)];
      }
      root.stats = counts;
    }
  }
}
