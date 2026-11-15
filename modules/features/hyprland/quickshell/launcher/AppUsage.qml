pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How much each app is used, so the launcher can put the usual ones first.
// A launch counts half as much a week later. Each app keeps one number,
// log2 of the sum of 2^(launch time in weeks): a launch adds to it with a
// log-sum-exp step, and as every app ages at the same rate, the numbers
// compare current use without ever being decayed. Saved in the state dir.
Singleton {
  id: root

  readonly property real week: 7 * 24 * 3600 * 1000

  // From 0 for an app never launched towards 1: ½ after one launch just now,
  // ¾ after two.
  function use(id: string): real {
    const rank = state.ranks[id];
    return rank === undefined ? 0 : 1 - Math.pow(2, -Math.pow(2, rank - Date.now() / week));
  }

  function launched(id: string): void {
    const now = Date.now() / week;
    const rank = state.ranks[id];
    // log2(2^rank + 2^now), without computing either power.
    const sum = rank === undefined ? now : Math.max(rank, now) + Math.log2(1 + Math.pow(2, -Math.abs(rank - now)));
    state.ranks = Object.assign({}, state.ranks, { [id]: sum });
  }

  FileView {
    path: Quickshell.statePath("launcher.json")
    // Until the first launch, there is no file, which is fine.
    printErrors: false
    // Deferred: writing at once loses a second change made in the same turn.
    onAdapterUpdated: Qt.callLater(writeAdapter)
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn(`Reading ${path} failed: ${FileViewError.toString(error)}`);
    }
    onSaveFailed: error => console.warn(`Writing ${path} failed: ${FileViewError.toString(error)}`)

    JsonAdapter {
      id: state

      // Desktop entry id to rank.
      property var ranks: ({})
    }
  }
}
