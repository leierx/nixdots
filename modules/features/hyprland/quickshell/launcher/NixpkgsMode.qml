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
  // The parsed columns cost a few hundred MiB; a second open within a moment keeps them, one after that reads the list again.
  readonly property int releaseDelay: 60000
  // Lines parsed per frame, so the launcher takes keys while a list is read.
  readonly property int chunk: 20000
  // Columns rather than an object per package, since there are over 130 000; read only while the launcher wants them, so the idle shell holds neither the file nor them.
  property bool loaded: false
  property var index: ({ rev: "", lines: [], attrs: [], names: [], texts: [] })
  // The list being parsed, a chunk a frame.
  property var parsing: null
  // A list fetched since this one was read, read on the next open, so a search never changes under the keys.
  property bool stale: false
  // What this open searched, so backspace finds a query's matches again and a longer one searches only those.
  readonly property var memo: ({ state: null })

  function parse(text: string): void {
    const lines = text.split("\n");
    const head = lines.shift().split("\t");
    if (lines[lines.length - 1] === "") lines.pop();
    root.parsing = { rev: head[0], lines, attrs: new Array(lines.length), names: new Array(lines.length), texts: new Array(lines.length), at: 0 };
    parser.start();
  }

  function unload(): void {
    parser.stop();
    root.parsing = null;
    root.loaded = false;
    root.index = ({ rev: "", lines: [], attrs: [], names: [], texts: [] });
    root.memo.state = null;
    // The engine holds the parsed columns' pages until asked, so the release is what gives the memory back.
    gc();
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

  function prepare(index: var): var {
    const uses = AppUsage.uses(root.prefix);
    const wanted = new Set(Object.keys(uses));
    const boost = new Float64Array(index.attrs.length);
    const used = [];
    for (let i = 0; wanted.size > 0 && i < index.attrs.length; i++) {
      if (!wanted.has(index.attrs[i])) continue;
      boost[i] = 50 * uses[index.attrs[i]];
      used.push(i);
    }
    used.sort((a, b) => boost[b] - boost[a]);
    return { index, ranks: AppUsage.ranks, boost, recent: used.slice(0, root.limit).map(i => root.row(index, i)), queries: Object.create(null) };
  }

  name: "nixpkgs"
  title: "Run from nixpkgs"
  image: Quickshell.iconPath("nix-snowflake", "package-x-generic")
  placeholder: "Run a package from nixpkgs…"
  nothing: "Type a Package Name"
  loading: root.index.lines.length === 0
  fields: row => [[1.0, row.title], [0.5, row.subtitle]]

  find: query => {
    const index = root.index;
    // Ranks change only with a launch; the boosts read the clock, so this open keeps the ones it began with.
    let state = root.memo.state;
    if (!state || state.index !== index || state.ranks !== AppUsage.ranks) state = root.memo.state = root.prepare(index);
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
    const limit = root.limit;
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
      if (best.length === limit && ranked <= best[best.length - 1].ranked) continue;
      let at = best.length;
      while (at > 0 && best[at - 1].ranked < ranked) at--;
      best.splice(at, 0, { ranked, i });
      if (best.length > limit) best.pop();
    }
    const rows = best.map(match => root.row(index, match.i));
    memo[lowered] = { matched, rows };
    return rows;
  }

  onOpened: {
    unloadTimer.stop();
    // Read again now: a list fetched since the last read, or one released a minute after the last close.
    if (root.stale && root.loaded) list.reload();
    root.stale = false;
    root.loaded = true;
    refresh.running = true;
  }
  onOpenChanged: {
    if (!open) {
      root.memo.state = null;
      unloadTimer.restart();
    }
  }

  Timer {
    id: unloadTimer

    interval: root.releaseDelay
    onTriggered: root.unload()
  }

  Timer {
    id: parser

    // A QML Timer at 0 never fires.
    interval: 1
    repeat: true
    onTriggered: {
      const job = root.parsing;
      if (!job) {
        stop();
        return;
      }
      const end = Math.min(job.lines.length, job.at + root.chunk);
      for (let i = job.at; i < end; i++) {
        const fields = job.lines[i].split("\t", 2);
        job.attrs[i] = fields[0];
        job.names[i] = `${fields[0]} ${fields[1]}`.toLowerCase();
        job.texts[i] = job.lines[i].replace(/\t/g, " ").toLowerCase();
      }
      job.at = end;
      if (end < job.lines.length) return;
      stop();
      root.parsing = null;
      root.index = { rev: job.rev, lines: job.lines, attrs: job.attrs, names: job.names, texts: job.texts };
    }
  }

  onActivated: row => {
    AppUsage.launched(root.prefix + row.attr);
    Detached.run(["nixpkgs-run", root.index.rev, row.attr, row.program], "");
    Panels.close();
  }

  // Its text goes with its path, so a released list leaves nothing behind.
  FileView {
    id: list

    path: root.loaded ? Quickshell.cachePath("nixpkgs.tsv") : ""
    // There is no file until the first fetch.
    printErrors: false
    onLoaded: root.parse(list.text())
  }

  Command {
    id: refresh

    name: "nixpkgs-index"
    // Outside the shell's cgroup: jq holds the whole list a while, which the shell's memory limit has no room for.
    command: ["systemd-run", "--user", "--scope", "--quiet", "nixpkgs-index", Quickshell.cachePath("nixpkgs.tsv")]
    // Only an open with no list waits on it; at login the network may not be up yet.
    quiet: !root.open || root.index.lines.length > 0
    // The channel's list is hundreds of megabytes on a slow line.
    timeout: 0
    onDone: output => {
      if (output.trim() !== "updated") return;
      if (root.open && root.index.lines.length === 0 && root.parsing === null) list.reload();
      else root.stale = true;
    }
  }
}
