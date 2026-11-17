pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Each app keeps log2 of the sum of 2^(launch time in weeks), so a launch counts
// half as much a week later, and as all apps age alike the numbers never need decaying.
Singleton {
  id: root

  readonly property real week: 7 * 24 * 3600 * 1000

  function use(id: string): real {
    const rank = state.ranks[id];
    return rank === undefined ? 0 : 1 - Math.pow(2, -Math.pow(2, rank - Date.now() / week));
  }

  function uses(prefix: string): var {
    const found = {};
    for (const id in state.ranks) {
      if (id.startsWith(prefix)) found[id.slice(prefix.length)] = root.use(id);
    }
    return found;
  }

  function launched(id: string): void {
    const now = Date.now() / week;
    const rank = state.ranks[id];
    // log2(2^rank + 2^now), without computing either power.
    const sum = rank === undefined ? now : Math.max(rank, now) + Math.log2(1 + Math.pow(2, -Math.abs(rank - now)));
    state.ranks = Object.assign({}, state.ranks, { [id]: sum });
  }

  StateFile {
    name: "launcher.json"

    JsonAdapter {
      id: state

      property var ranks: ({})
    }
  }
}
