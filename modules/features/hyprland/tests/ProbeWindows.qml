pragma Singleton

import Quickshell

Singleton {
  property var markers: []
  // Each window once, named by its own file rather than common/Overlay's.
  readonly property var windows: {
    const found = new Map();
    for (const marker of markers) {
      if (!marker.window) continue;
      const name = marker.file.split("/").pop();
      if (!found.has(marker.window) || found.get(marker.window) === "Overlay") found.set(marker.window, name);
    }
    return Array.from(found, ([window, name]) => ({ window, name }));
  }
}
