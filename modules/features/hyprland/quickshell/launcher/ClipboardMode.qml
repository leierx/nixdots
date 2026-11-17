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
  // Material Symbols' assignment
  glyph: "M200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h168q13-36 43.5-58t68.5-22q38 0 68.5 22t43.5 58h168q33 0 56.5 23.5T840-760v560q0 33-23.5 56.5T760-120H200Zm0-80h560v-560H200v560Zm120-80h200q17 0 28.5-11.5T560-320q0-17-11.5-28.5T520-360H320q-17 0-28.5 11.5T280-320q0 17 11.5 28.5T320-280Zm0-160h320q17 0 28.5-11.5T680-480q0-17-11.5-28.5T640-520H320q-17 0-28.5 11.5T280-480q0 17 11.5 28.5T320-440Zm0-160h320q17 0 28.5-11.5T680-640q0-17-11.5-28.5T640-680H320q-17 0-28.5 11.5T280-640q0 17 11.5 28.5T320-600Zm160-190q13 0 21.5-8.5T510-820q0-13-8.5-21.5T480-850q-13 0-21.5 8.5T450-820q0 13 8.5 21.5T480-790ZM200-200v-560 560Z"
  placeholder: "Search clipboard…"
  wide: true
  removable: true
  rows: root.entries.map(entry => {
    // "[[ binary data 140 KiB png 1920x1080 ]]"
    const image = /^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/.exec(entry.text);
    const stats = root.stats[entry.id];
    return Object.assign(image ? {
      title: "Image",
      subtitle: `${image[3]}×${image[4]} ${image[2].toUpperCase()}, ${image[1]}`,
      // Material Symbols' image
      glyph: "M200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h560q33 0 56.5 23.5T840-760v560q0 33-23.5 56.5T760-120H200Zm0-80h560v-560H200v560Zm0 0v-560 560Zm80-80h400q12 0 18-11t-2-21L586-459q-6-8-16-8t-16 8L450-320l-74-99q-6-8-16-8t-16 8l-80 107q-8 10-2 21t18 11Z",
      thumbnail: root.pictures[entry.id] ? `file://${root.cache}/${entry.id}` : "",
      size: { width: Number(image[3]), height: Number(image[4]) },
    } : {
      title: entry.text,
      subtitle: stats ? `${root.plural(stats[1], "character")}, ${root.plural(stats[0], "line")}` : "",
      // Material Symbols' link and notes
      glyph: /^https?:\/\/\S+$/.test(entry.text)
        ? "M280-280q-83 0-141.5-58.5T80-480q0-83 58.5-141.5T280-680h120q17 0 28.5 11.5T440-640q0 17-11.5 28.5T400-600H280q-50 0-85 35t-35 85q0 50 35 85t85 35h120q17 0 28.5 11.5T440-320q0 17-11.5 28.5T400-280H280Zm80-160q-17 0-28.5-11.5T320-480q0-17 11.5-28.5T360-520h240q17 0 28.5 11.5T640-480q0 17-11.5 28.5T600-440H360Zm200 160q-17 0-28.5-11.5T520-320q0-17 11.5-28.5T560-360h120q50 0 85-35t35-85q0-50-35-85t-85-35H560q-17 0-28.5-11.5T520-640q0-17 11.5-28.5T560-680h120q83 0 141.5 58.5T880-480q0 83-58.5 141.5T680-280H560Z"
        : "M160-240q-17 0-28.5-11.5T120-280q0-17 11.5-28.5T160-320h400q17 0 28.5 11.5T600-280q0 17-11.5 28.5T560-240H160Zm0-200q-17 0-28.5-11.5T120-480q0-17 11.5-28.5T160-520h640q17 0 28.5 11.5T840-480q0 17-11.5 28.5T800-440H160Zm0-200q-17 0-28.5-11.5T120-680q0-17 11.5-28.5T160-720h640q17 0 28.5 11.5T840-680q0 17-11.5 28.5T800-640H160Z",
    }, { key: entry.id, id: entry.id, line: entry.line });
  })
  fields: row => [[1.0, row.title], [1.0, row.subtitle]]

  // At the start too, so pictures from a history wiped at login leave the cache.
  Component.onCompleted: cacheCommand.running = true
  onOpened: listCommand.running = true
  onOpenChanged: if (!open) entries = []
  onActivated: row => {
    Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", row.id]);
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
