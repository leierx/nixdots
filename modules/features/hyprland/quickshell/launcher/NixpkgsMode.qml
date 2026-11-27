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
  // The list is let go of a moment after the launcher closes; a second open within it keeps it, one after that reads the list again.
  readonly property int releaseDelay: 60000
  // Lines indexed per frame, so the launcher takes keys while a list is read.
  readonly property int chunk: 20000
  // The list as two strings, as read and lowered, and where each line and its name end lie in them: a few large blocks, which a release gives back whole, where a string per package left the engine holding pages. Read only while the launcher wants it, so the idle shell holds none of it.
  property bool loaded: false
  property var index: root.empty()
  // The list being indexed, a chunk a frame.
  property var parsing: null
  // A list fetched since this one was read, read on the next open, so a search never changes under the keys.
  property bool stale: false
  // What this open searched, so backspace finds a query's rows again.
  readonly property var memo: ({ state: null })

  function empty(): var {
    return { rev: "", text: "", lower: "", starts: new Int32Array(1), names: new Int32Array(0), count: 0 };
  }

  function parse(text: string): void {
    const head = text.indexOf("\n");
    // Lowered in one piece, at the same length, so one offset serves both: U+0130 is the one capital whose lowering is longer.
    const lower = text.replace(/\u0130/g, "I").toLowerCase().replace(/\t/g, " ");
    let lines = 0;
    for (let at = head; at >= 0 && at + 1 < text.length; at = text.indexOf("\n", at + 1)) lines++;
    root.parsing = { rev: (head < 0 ? text : text.slice(0, head)).split("\t")[0], text, lower, starts: new Int32Array(lines + 1), names: new Int32Array(lines), count: 0, at: head < 0 ? text.length : head + 1, tab: text.indexOf("\t", head + 1) };
    parser.start();
  }

  function unload(): void {
    parser.stop();
    root.parsing = null;
    root.loaded = false;
    root.index = root.empty();
    root.memo.state = null;
    // The engine holds what it let go of until asked.
    gc();
  }

  // The line holding offset `at`.
  function lineAt(index: var, at: int): int {
    let low = 0;
    let high = index.count - 1;
    while (low < high) {
      const middle = (low + high + 1) >> 1;
      if (index.starts[middle] <= at) low = middle;
      else high = middle - 1;
    }
    return low;
  }

  function row(index: var, i: int): var {
    // By index: Qt 6.12 fills names a short array has no element for with stale values (TODO.md), here the line's own columns.
    const fields = index.text.slice(index.starts[i], index.starts[i + 1] - 1).split("\t");
    const attr = fields[0];
    const program = fields[1] ?? "";
    const version = fields[2] ?? "";
    const unfree = fields[3] ?? "";
    const description = fields[4] ?? "";
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
    const boost = new Float64Array(index.count);
    const used = [];
    for (const attr in uses) {
      const at = index.count === 0 ? -1 : index.text.indexOf(`\n${attr}\t`, index.starts[0] - 1);
      if (at < 0) continue;
      const i = root.lineAt(index, at + 1);
      boost[i] = 50 * uses[attr];
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
  loading: root.index.count === 0
  fields: row => [[1.0, row.title], [0.5, row.subtitle]]

  find: query => {
    const index = root.index;
    // Ranks change only with a launch; the boosts read the clock, so this open keeps the ones it began with.
    let state = root.memo.state;
    if (!state || state.index !== index || state.ranks !== AppUsage.ranks) state = root.memo.state = root.prepare(index);
    const typed = Search.words(query);
    if (typed.length === 0) return state.recent;

    const lowered = typed.join(" ");
    if (state.queries[lowered]) return state.queries[lowered];
    const { lower, starts, names, count } = index;
    // Per line: the words found so far, each at its first place in the line; a line whose name holds them all ranks as a name match, otherwise at half as a match in its description.
    const found = new Uint8Array(count);
    const outside = new Uint8Array(count);
    const points = new Float64Array(count);
    for (let w = 0; w < typed.length; w++) {
      const word = typed[w];
      let line = 0;
      // A line's first place only: the search goes on from the next line.
      for (let at = lower.indexOf(word, starts[0]); at >= 0 && line < count; at = line < count ? lower.indexOf(word, starts[line]) : -1) {
        while (starts[line + 1] <= at) line++;
        if (line >= count) break;
        if (found[line] === w) {
          const before = at === starts[line] ? -1 : lower.charCodeAt(at - 1);
          // Search.scoreLowered's: the start, after a separator (space, - _ . / :), or within a word.
          points[line] += before < 0 ? 1000 : before === 32 || before === 45 || before === 95 || before === 46 || before === 47 || before === 58 ? 900 : 700;
          if (at + word.length > names[line]) outside[line] = 1;
          found[line] = w + 1;
        }
        line++;
      }
    }
    const boost = state.boost;
    const limit = root.limit;
    // The best few, kept in order as they come, rather than sorting every match.
    const best = [];
    const words = typed.length;
    for (let i = 0; i < count; i++) {
      if (found[i] !== words) continue;
      const length = outside[i] ? starts[i + 1] - 1 - starts[i] : names[i] - starts[i];
      const ranked = (outside[i] ? 0.5 : 1) * (points[i] - length / 20) + boost[i];
      if (best.length === limit && ranked <= best[best.length - 1].ranked) continue;
      let at = best.length;
      while (at > 0 && best[at - 1].ranked < ranked) at--;
      best.splice(at, 0, { ranked, i });
      if (best.length > limit) best.pop();
    }
    const rows = best.map(match => root.row(index, match.i));
    state.queries[lowered] = rows;
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
      const { text, starts, names } = job;
      // Tabs found once, front to back, so a list without them costs no more than one with.
      let tab = job.tab;
      for (let n = 0; n < root.chunk && job.at < text.length; n++) {
        const start = job.at;
        let end = text.indexOf("\n", start);
        if (end < 0) end = text.length;
        while (tab >= 0 && tab < start) tab = text.indexOf("\t", start);
        // The name is the attribute and its program, up to the second tab.
        let name = end;
        if (tab >= 0 && tab < end) {
          tab = text.indexOf("\t", tab + 1);
          if (tab >= 0 && tab < end) name = tab;
        }
        starts[job.count] = start;
        names[job.count] = name;
        job.count++;
        job.at = end + 1;
      }
      job.tab = tab;
      if (job.at < text.length) return;
      stop();
      starts[job.count] = job.at;
      root.parsing = null;
      root.index = { rev: job.rev, text, lower: job.lower, starts: starts.subarray(0, job.count + 1), names: names.subarray(0, job.count), count: job.count };
    }
  }

  onActivated: row => {
    const id = root.prefix + row.attr;
    Detached.run(["nixpkgs-run", root.index.rev, row.attr, row.program], "");
    Panels.close();
    // New ranks search again: a turn later the launch is on its way and the closed window gone.
    Qt.callLater(() => AppUsage.launched(id));
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
    quiet: !root.open || root.index.count > 0
    // The channel's list is hundreds of megabytes on a slow line.
    timeout: 0
    onDone: output => {
      if (output.trim() !== "updated") return;
      if (root.open && root.index.count === 0 && root.parsing === null) list.reload();
      else root.stale = true;
    }
  }
}
