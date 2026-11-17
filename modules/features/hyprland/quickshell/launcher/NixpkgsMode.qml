import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import "search.js" as Search

LauncherMode {
  id: root

  readonly property string prefix: "nixpkgs:"
  readonly property int limit: 50
  // Columns rather than an object per package, since there are over 130 000.
  property var index: ({ rev: "", lines: [], attrs: [], names: [], texts: [] })
  // A list fetched while open waits for the close, so a search never changes under the keys.
  property bool stale: false
  // A query typed further only searches what the last one matched.
  readonly property var memo: ({ index: null, query: "", matched: [] })

  function parse(text: string): void {
    const lines = text.split("\n");
    const head = lines.shift().split("\t");
    if (lines[lines.length - 1] === "") lines.pop();
    const attrs = new Array(lines.length);
    const names = new Array(lines.length);
    const texts = new Array(lines.length);
    for (let i = 0; i < lines.length; i++) {
      const fields = lines[i].split("\t", 2);
      attrs[i] = fields[0];
      names[i] = `${fields[0]} ${fields[1]}`.toLowerCase();
      texts[i] = lines[i].replace(/\t/g, " ").toLowerCase();
    }
    root.index = { rev: head[0], lines, attrs, names, texts };
  }

  function row(index: var, i: int): var {
    const [attr, program, version, unfree, description] = index.lines[i].split("\t");
    return {
      key: attr,
      title: attr,
      subtitle: [version, unfree, description].filter(part => part).join(" · "),
      // Material Symbols' deployed_code
      glyph: "M440-183v-274L200-596v274l240 139Zm80 0 240-139v-274L520-457v274Zm-40-343 237-137-237-137-237 137 237 137ZM160-252q-19-11-29.5-29T120-321v-318q0-22 10.5-40t29.5-29l280-161q19-11 40-11t40 11l280 161q19 11 29.5 29t10.5 40v318q0 22-10.5 40T800-252L520-91q-19 11-40 11t-40-11L160-252Zm320-228Z",
      attr,
      program,
    };
  }

  function recent(index: var, uses: var): var {
    const wanted = new Set(Object.keys(uses));
    if (wanted.size === 0) return [];
    const found = [];
    for (let i = 0; i < index.attrs.length; i++) {
      if (wanted.has(index.attrs[i])) found.push(i);
    }
    return found
      .sort((a, b) => uses[index.attrs[b]] - uses[index.attrs[a]])
      .slice(0, root.limit)
      .map(i => root.row(index, i));
  }

  name: "nixpkgs"
  title: "Run from nixpkgs"
  image: Qt.resolvedUrl("../common/nixos.svg")
  accent: [Theme.nixosLight, Theme.nixosDark]
  placeholder: root.index.lines.length > 0 ? "Run a package from nixpkgs…" : "Fetching the package list…"
  fields: row => [[1.0, row.title], [0.5, row.subtitle]]

  find: query => {
    const index = root.index;
    const uses = AppUsage.uses(root.prefix);
    const typed = Search.words(query);
    if (typed.length === 0) return root.recent(index, uses);

    const lowered = typed.join(" ");
    const memo = root.memo;
    const pool = memo.index === index && lowered.startsWith(memo.query) ? memo.matched : null;
    const count = pool ? pool.length : index.attrs.length;
    const matched = [];
    // The best few, kept in order as they come, rather than sorting every match.
    const best = [];
    for (let k = 0; k < count; k++) {
      const i = pool ? pool[k] : k;
      const score = Math.max(Search.scoreLowered(typed, index.names[i]), 0.5 * Search.scoreLowered(typed, index.texts[i]));
      if (score < 0) continue;
      matched.push(i);
      const ranked = score + 50 * (uses[index.attrs[i]] ?? 0);
      if (best.length === root.limit && ranked <= best[best.length - 1].ranked) continue;
      let at = best.length;
      while (at > 0 && best[at - 1].ranked < ranked) at--;
      best.splice(at, 0, { ranked, i });
      if (best.length > root.limit) best.pop();
    }
    memo.index = index;
    memo.query = lowered;
    memo.matched = matched;
    return best.map(match => root.row(index, match.i));
  }

  onOpened: refresh.running = true
  onOpenChanged: {
    if (!open && stale) {
      stale = false;
      list.reload();
    }
  }
  onActivated: row => {
    AppUsage.launched(root.prefix + row.attr);
    Quickshell.execDetached({
      command: ["systemd-run", "--user", "--scope", "--quiet", "nixpkgs-run", root.index.rev, row.attr, row.program],
      environment: ({ QT_SCALE_FACTOR: null }),
    });
    Panels.close();
  }

  Component.onCompleted: refresh.running = true

  FileView {
    id: list

    path: Quickshell.cachePath("nixpkgs.tsv")
    // There is no file until the first fetch.
    printErrors: false
    onLoaded: root.parse(list.text())
  }

  Command {
    id: refresh

    name: "nixpkgs-index"
    command: ["nixpkgs-index", list.path]
    quiet: root.index.lines.length > 0
    onDone: output => {
      if (output.trim() !== "updated") return;
      if (root.open && root.index.lines.length > 0) root.stale = true;
      else list.reload();
    }
  }
}
