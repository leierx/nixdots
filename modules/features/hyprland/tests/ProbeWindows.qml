pragma Singleton

import Quickshell

Singleton {
  property var markers: []
  // Each window once, named by its own file rather than common/Overlay's or Popover's.
  readonly property var windows: {
    const found = new Map();
    for (const marker of markers) {
      if (!marker.window) continue;
      const name = marker.file.split("/").pop();
      const shared = ["Overlay", "Popover"];
      if (!found.has(marker.window) || shared.includes(found.get(marker.window)) && !shared.includes(name)) found.set(marker.window, name);
    }
    return Array.from(found, ([window, name]) => ({ window, name }));
  }
}
