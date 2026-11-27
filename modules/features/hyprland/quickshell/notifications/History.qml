pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import "history.js" as Saved

Singleton {
  id: root

  readonly property string images: Quickshell.cachePath("notifications")
  // Read before anything is written, or the first save would empty it.
  property bool loaded: false
  // What the file holds, so a save that changes nothing writes nothing; no file holds an empty history.
  property string written: ""

  signal restored(var records)

  function finish(records: var): void {
    root.loaded = true;
    root.restored(records);
  }

  // LIVE: the uids of every entry shown, whose copies stay whether saved or not.
  function save(records: var, live: var): void {
    if (!root.loaded) return;
    const kept = Saved.current(records, Date.now());
    const text = Saved.serialise(kept);
    if (text === root.written) return;
    root.written = text;
    file.setText(text);
    // A picture saved since this list was made may be one it has not seen yet.
    prune.command = ["sh", "-c", 'mkdir -p "$1" && cd "$1" && since=$2 && shift 2 && find . -maxdepth 1 -name "*.png" ! -newermt "@$since" | while read -r file; do file=${file#./}; case " $* " in *" ${file%%-*} "*) ;; *) rm -f "$file" ;; esac; done', "sh", root.images, String(Date.now() / 1000), ...kept.map(record => record.uid), ...live];
    if (prune.running) prune.again = true;
    else prune.running = true;
  }

  FileView {
    id: file

    path: Quickshell.statePath("notification-history.json")
    // There is no file until the first save.
    printErrors: false
    onLoaded: {
      root.written = file.text();
      const saved = Saved.parse(root.written, Date.now());
      if (saved.problem) console.warn(`${file.path}: ${saved.problem}; starting afresh`);
      root.finish(saved.records);
    }
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn(`Reading ${file.path} failed: ${FileViewError.toString(error)}`);
      else root.written = Saved.serialise([]);
      root.finish([]);
    }
    onSaveFailed: error => {
      console.warn(`Writing ${file.path} failed: ${FileViewError.toString(error)}`);
      // The file still holds what it did, so the next save tries again.
      root.written = "";
    }
  }

  // Also makes the directory the pictures are saved into.
  Command {
    id: prune

    // A save while it ran, whose list it has not seen.
    property bool again: false

    name: "Pruning saved notification pictures"
    quiet: true
    command: ["mkdir", "-p", root.images]
    Component.onCompleted: running = true
    onRunningChanged: {
      if (running || !again) return;
      again = false;
      Qt.callLater(() => prune.running = true);
    }
  }
}
