import QtQuick
import Quickshell
import qs.common
import qs.nix

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
  nothing: "Nothing Copied Yet"
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
  // A clip's own text; a picture's size and format too, as it has no text. A count would match every clip.
  fields: row => row.size ? [[1.0, row.title], [0.8, row.subtitle]] : [[1.0, row.title]]
  loading: listCommand.running

  // At the start too, so pictures from a history wiped at login leave the cache.
  Component.onCompleted: cacheCommand.running = true
  onOpened: listCommand.running = true
  onOpenChanged: if (!open) entries = []
  // Decoded first, so a clip that fails to decode says so rather than emptying the clipboard; each into a file of its own, which its wl-copy removes.
  onActivated: row => {
    decoding.createObject(root, { command: ["sh", "-c", 'mkdir -p "$(dirname "$2")" && file=$(mktemp "$2.XXXXXX") && { cliphist decode "$1" > "$file" || { rm -f "$file"; exit 1; }; } && printf %s "$file"', "sh", row.id, Quickshell.cachePath("clipboard-picked")] });
    Panels.close();
  }
  onRemoved: row => {
    deletion.createObject(root, { command: ["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", row.line] });
    root.entries = root.entries.filter(entry => entry.id !== row.id);
  }

  // One per action: a Process given a new command while it runs starts only the last one it was given.
  Component {
    id: decoding

    Command {
      name: "Copying the clip"
      running: true
      // wl-copy stays behind to serve the clip, in a scope of its own; it has read the file before it forks.
      onDone: output => {
        Detached.run(["sh", "-c", 'wl-copy < "$1"; rm -f "$1"', "sh", output], "");
        destroy();
      }
      onFailed: destroy()
    }
  }

  Component {
    id: deletion

    Command {
      name: "Deleting the clip"
      running: true
      onDone: destroy()
      onFailed: destroy()
    }
  }

  // The rows show at once; what needs a clip decoded follows from the cache.
  Command {
    id: listCommand

    name: "cliphist list"
    // cliphist has no database until the first copy, and says so as an error: an empty history, not a failure.
    command: ["sh", "-c", 'out=$(cliphist list 2>&1) && { printf "%s\\n" "$out"; exit; }; case $out in *"store something first"*) exit 0 ;; esac; printf "%s\\n" "$out" >&2; exit 1']
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
    // Nobody waits on the thumbnails and counts: a failure only reaches the log.
    quiet: true
    // Every picture decoded once, on a first pass over a long history.
    timeout: 120000
    command: ["sh", "-c", `
      set -f
      mkdir -p "$1" && cd "$1" || exit
      list=$(cliphist list 2>&1) || case $list in *"store something first"*) list="" ;; *) printf '%s\\n' "$list" >&2; exit 1 ;; esac
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
