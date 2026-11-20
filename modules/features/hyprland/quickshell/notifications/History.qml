pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import "history.js" as Saved

// The notification history on disk, so a restart of the shell keeps it, with the pictures only the server held.
Singleton {
  id: root

  readonly property string images: Quickshell.cachePath("notifications")
  // Read before anything is written, or the first save would empty it.
  property bool loaded: false

  signal restored(var records)

  function finish(records: var): void {
    root.loaded = true;
    root.restored(records);
  }

  function save(records: var): void {
    if (!root.loaded) return;
    const text = Saved.serialise(records, Date.now());
    file.setText(text);
    prune.command = ["sh", "-c", 'mkdir -p "$1" && cd "$1" && shift && for file in *.png; do [ -e "$file" ] || continue; case " $* " in *" ${file%%-*} "*) ;; *) rm -f "$file" ;; esac; done', "sh", root.images, ...JSON.parse(text).notifications.map(record => record.uid)];
    if (!prune.running) prune.running = true;
  }

  FileView {
    id: file

    path: Quickshell.statePath("notification-history.json")
    // There is no file until the first save.
    printErrors: false
    onLoaded: {
      const saved = Saved.parse(file.text(), Date.now());
      if (saved.problem) console.warn(`${file.path}: ${saved.problem}; starting afresh`);
      root.finish(saved.records);
    }
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn(`Reading ${file.path} failed: ${FileViewError.toString(error)}`);
      root.finish([]);
    }
    onSaveFailed: error => console.warn(`Writing ${file.path} failed: ${FileViewError.toString(error)}`)
  }

  // Also makes the directory the pictures are saved into.
  Command {
    id: prune

    name: "Pruning saved notification pictures"
    quiet: true
    command: ["mkdir", "-p", root.images]
    Component.onCompleted: running = true
  }
}
