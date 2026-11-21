import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.nix
import "search.js" as Search

LauncherMode {
  id: root

  readonly property string prefix: "nixpkgs:"
  readonly property int limit: 50
  // Columns rather than an object per package, since there are over 130 000.
  property var index: ({ rev: "", lines: [], attrs: [], names: [], texts: [] })
  // A list fetched while open waits for the close, so a search never changes under the keys.
  property bool stale: false
  // What this open searched, so backspace finds a query's matches again and a longer one searches only those.
  readonly property var memo: ({ state: null })

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
      glyph: Symbols.packages,
      attr,
      program,
    };
  }

  function prepare(index: var, uses: var): var {
    const wanted = new Set(Object.keys(uses));
    const boost = new Float64Array(index.attrs.length);
    const used = [];
    for (let i = 0; wanted.size > 0 && i < index.attrs.length; i++) {
      if (!wanted.has(index.attrs[i])) continue;
      boost[i] = 50 * uses[index.attrs[i]];
      used.push(i);
    }
    used.sort((a, b) => boost[b] - boost[a]);
    return { index, uses: JSON.stringify(uses), boost, recent: used.slice(0, root.limit).map(i => root.row(index, i)), queries: Object.create(null) };
  }

  name: "nixpkgs"
  title: "Run from nixpkgs"
  image: Quickshell.iconPath("nix-snowflake", "package-x-generic")
  placeholder: root.index.lines.length > 0 ? "Run a package from nixpkgs…" : "Fetching the package list…"
  nothing: root.index.lines.length > 0 ? "Type a Package Name" : ""
  fields: row => [[1.0, row.title], [0.5, row.subtitle]]

  find: query => {
    const index = root.index;
    const uses = AppUsage.uses(root.prefix);
    let state = root.memo.state;
    if (!state || state.index !== index || state.uses !== JSON.stringify(uses)) state = root.memo.state = root.prepare(index, uses);
    const typed = Search.words(query);
    if (typed.length === 0) return state.recent;

    const lowered = typed.join(" ");
    const memo = state.queries;
    if (memo[lowered]) return memo[lowered].rows;
    let pool = null;
    for (const query in memo) {
      if (lowered.startsWith(query) && (!pool || memo[query].matched.length < pool.length)) pool = memo[query].matched;
    }
    const count = pool ? pool.length : index.attrs.length;
    const names = index.names;
    const texts = index.texts;
    const boost = state.boost;
    const words = typed.length;
    const matched = [];
    // The best few, kept in order as they come, rather than sorting every match.
    const best = [];
    // Search.scoreLowered inlined: a call per package costs ten times the matching.
    for (let k = 0; k < count; k++) {
      const i = pool ? pool[k] : k;
      let text = names[i];
      let weight = 1;
      let score = 0;
      for (let w = 0; w < words; w++) {
        const at = text.indexOf(typed[w]);
        if (at < 0) {
          // A description match at half weight never beats a name match, so it is only looked at without one.
          if (weight === 0.5) {
            score = -1;
            break;
          }
          text = texts[i];
          weight = 0.5;
          score = 0;
          w = -1;
          continue;
        }
        score += at === 0 ? 1000 : " -_./:".indexOf(text[at - 1]) >= 0 ? 900 : 700;
      }
      if (score < 0) continue;
      score = weight * (score - text.length / 20);
      matched.push(i);
      const ranked = score + boost[i];
      if (best.length === root.limit && ranked <= best[best.length - 1].ranked) continue;
      let at = best.length;
      while (at > 0 && best[at - 1].ranked < ranked) at--;
      best.splice(at, 0, { ranked, i });
      if (best.length > root.limit) best.pop();
    }
    const rows = best.map(match => root.row(index, match.i));
    memo[lowered] = { matched, rows };
    return rows;
  }

  onOpened: refresh.running = true
  onOpenChanged: {
    if (!open) root.memo.state = null;
    if (!open && stale) {
      stale = false;
      list.reload();
    }
  }
  onActivated: row => {
    AppUsage.launched(root.prefix + row.attr);
    Detached.run(["nixpkgs-run", root.index.rev, row.attr, row.program], "");
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
    // Only an open with no list waits on it; at login the network may not be up yet.
    quiet: !root.open || root.index.lines.length > 0
    onDone: output => {
      if (output.trim() !== "updated") return;
      if (root.open && root.index.lines.length > 0) root.stale = true;
      else list.reload();
    }
  }
}
