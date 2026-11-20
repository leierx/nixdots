import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.bar
import qs.center
import qs.common
import qs.notifications
import qs.osd

// qs-test adds this to the session's copy of the shell only: `qst state` is its `state`.
Scope {
  id: probe

  // Sizes and corners that are not a role's, by the type that draws them.
  readonly property var ownShapes: ({
    Battery: "a meter drawn to its own scale",
    LayoutDiagram: "outputs drawn to scale",
    PowerMenu: "the power tiles' large squircles",
    TrayMenu: "libadwaita's check box"
  })

  readonly property string scale: Quickshell.env("QT_SCALE_FACTOR") ?? "1"

  property bool recording: false
  property var tracks: null
  property real started: 0

  function typeOf(object: var): string {
    return String(object).replace(/\([^]*$/, "").replace(/_QML.*$/, "").split("::").pop();
  }

  function addressOf(object: var): string {
    return /\((0x[0-9a-f]+)/.exec(String(object))?.[1] ?? "";
  }

  function key(color: color): string {
    return [color.r, color.g, color.b, color.a].map(channel => Math.round(channel * 255)).join(",");
  }

  // Theme's colours, and its translucent ones made solid over the surfaces the shell draws on.
  property var allowedColors: new Set()

  Component.onCompleted: {
    const allowed = new Set(["0,0,0,0"]);
    for (const name in Theme) {
      const color = Theme[name];
      if (color === null || typeof color !== "object" || color.hslLightness === undefined) continue;
      allowed.add(key(color));
      if (color.a < 1) for (const base of [Theme.bg, Theme.panel]) allowed.add(key(Qt.tint(base, color)));
    }
    allowedColors = allowed;
  }

  // Each visible window with its visible items, their opacity on screen and their place in the window.
  function windows(): var {
    return ProbeWindows.windows.filter(({ window }) => window.visible && window.contentItem).map(({ window, name }) => {
      const items = [];
      const visit = (item, opacity) => {
        if (!item || !item.visible) return;
        const shown = opacity * item.opacity;
        if (shown <= 0.01) return;
        items.push({ item, opacity: shown });
        for (let i = 0; i < item.children.length; i++) visit(item.children[i], shown);
      };
      visit(window.contentItem, 1);
      return { window, items, type: name, screen: window.screen?.name ?? "" };
    });
  }

  function isText(o: var): bool {
    return "lineCount" in o && "elide" in o && "font" in o;
  }

  function isImage(o: var): bool {
    return "sourceSize" in o && "status" in o && "fillMode" in o;
  }

  function isRect(o: var): bool {
    return "radius" in o && "border" in o && "gradient" in o;
  }

  function isMouseArea(o: var): bool {
    return "acceptedButtons" in o && "cursorShape" in o && "containsMouse" in o;
  }

  function ancestorTypes(item: var): var {
    const types = [];
    for (let at = item; at; at = at.parent) types.push(typeOf(at));
    return types;
  }

  function label(entry: var, item: var): string {
    const text = isText(item) ? ` "${String(item.text).slice(0, 24)}"` : "";
    return `${entry.type}/${typeOf(item)}${text}`;
  }

  function luminance(color: color): real {
    const linear = channel => channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
  }

  function over(top: color, bottom: color): color {
    return Qt.rgba(top.r * top.a + bottom.r * (1 - top.a), top.g * top.a + bottom.g * (1 - top.a), top.b * top.a + bottom.b * (1 - top.a), 1);
  }

  // What lies behind an item: its window's colour, or the view background where the window is see-through, under its filled ancestors.
  function behind(entry: var, item: var): color {
    const fills = [];
    for (let at = item.parent; at; at = at.parent) if (isRect(at) && at.color.a > 0) fills.unshift(at);
    let color = entry.window.color.a > 0.99 ? entry.window.color : Theme.bg;
    for (const fill of fills) color = over(fill.color, color);
    return color;
  }

  // What should never be on screen, in whatever state the shell is in.
  function census(): var {
    const problems = [];
    for (const entry of windows()) {
      const width = entry.window.width;
      const height = entry.window.height;
      if (!("exclusionMode" in entry.window)) problems.push(`${entry.type} is not a layer surface: a popup window lands off on any monitor not at x 0`);
      for (const { item, opacity } of entry.items) {
        const type = typeOf(item);
        const own = entry.type in ownShapes || ancestorTypes(item).some(name => name in ownShapes);
        if (isText(item) && String(item.text).trim() !== "") {
          if (item.width < 1 || item.height < 1) problems.push(`${label(entry, item)} has no room: its text vanished`);
          const size = item.font.pointSize > 0 ? item.font.pointSize : item.font.pixelSize * 0.75;
          if (!own && size > 0 && size < 8) problems.push(`${label(entry, item)} is ${size} pt, too small to read`);
          if (opacity > 0.99 && key(item.color) !== key(Theme.fgFaint)) {
            const back = behind(entry, item);
            const front = over(item.color, back);
            const lighter = Math.max(luminance(front), luminance(back));
            const darker = Math.min(luminance(front), luminance(back));
            const ratio = (lighter + 0.05) / (darker + 0.05);
            if (ratio < 3) problems.push(`${label(entry, item)} has a contrast of ${ratio.toFixed(2)}:1 against what is behind it`);
          }
          if (!allowedColors.has(key(item.color))) problems.push(`${label(entry, item)} is coloured ${item.color}, which is not Theme's`);
        } else if (isImage(item)) {
          const source = String(item.source);
          if (source === "") problems.push(`${label(entry, item)} is shown without a source`);
          else if (item.status === Image.Error) problems.push(`${label(entry, item)} failed to load ${source}`);
        } else if (isRect(item) && (item.color.a > 0 || item.border.width > 0)) {
          const radius = item.radius;
          const half = Math.min(item.width, item.height) / 2;
          const inherited = item.parent && isRect(item.parent) && item.parent.radius === radius;
          const roles = [0, Theme.smallRadius, Theme.buttonRadius, Theme.cardRadius, Theme.windowRadius];
          if (!own && !inherited && !roles.includes(radius) && Math.abs(radius - half) > 0.6) problems.push(`${label(entry, item)} has a radius of ${radius}: neither Theme's nor half its size`);
          if (!own && item.color.a > 0 && !allowedColors.has(key(item.color))) problems.push(`${label(entry, item)} is coloured ${item.color}, which is not Theme's`);
          if (!own && item.border.width > 0 && !allowedColors.has(key(item.border.color))) problems.push(`${label(entry, item)} has a border coloured ${item.border.color}, which is not Theme's`);
        } else if (isMouseArea(item) && !item.enabled && item.cursorShape === Qt.PointingHandCursor) {
          problems.push(`${label(entry, item)} is disabled but still sets a pointing hand`);
        }
        if (type === "Card") {
          const at = item.mapToItem(null, 0, 0);
          if (at.x < -0.5 || at.y < -0.5 || at.x + item.width > width + 0.5 || at.y + item.height > height + 0.5) problems.push(`${label(entry, item)} at ${Math.round(at.x)},${Math.round(at.y)} ${Math.round(item.width)}x${Math.round(item.height)} runs off its ${Math.round(width)}x${Math.round(height)} window`);
        }
      }
    }
    return problems;
  }

  // Every mouse area on screen, with its middle in layout coordinates, for the cursor sweep; qs-test places each window by Hyprland's layers.
  function areas(): var {
    const found = [];
    for (const entry of windows()) {
      for (const { item } of entry.items) {
        const hovers = Array.from(item.data ?? []).some(child => child && "cursorShape" in child && "hovered" in child && "point" in child && !("width" in child));
        if (!(isMouseArea(item) || hovers) || item.width < 2 || item.height < 2) continue;
        const middle = item.mapToItem(null, item.width / 2, item.height / 2);
        // Rows a list has scrolled away are not under any pointer.
        let hidden = middle.x < 0 || middle.y < 0 || middle.x > entry.window.width || middle.y > entry.window.height;
        for (let at = item.parent; at && !hidden; at = at.parent) {
          if (!at.clip) continue;
          const inside = at.mapFromItem(null, middle.x, middle.y);
          hidden = inside.x < 0 || inside.y < 0 || inside.x > at.width || inside.y > at.height;
        }
        if (hidden) continue;
        found.push({ address: addressOf(item), label: label(entry, item), screen: entry.screen, window: [entry.window.width, entry.window.height], x: middle.x, y: middle.y, enabled: item.enabled, clicks: isMouseArea(item) && (item.acceptedButtons & Qt.LeftButton) !== 0, hand: isMouseArea(item) && item.cursorShape === Qt.PointingHandCursor });
      }
    }
    return found;
  }

  function describe(address: string): var {
    const object = findItem(address);
    if (!object) return null;
    return { type: typeOf(object), shape: ({ 0: "arrow", 4: "text", 13: "hand", 17: "open", 18: "closed" })[object.cursorShape] ?? null, enabled: object.enabled ?? null, clicks: isMouseArea(object) ? (object.acceptedButtons & Qt.LeftButton) !== 0 : null, buttons: isMouseArea(object) ? object.acceptedButtons : null };
  }

  function findItem(address: string): var {
    for (const entry of windows()) for (const { item } of entry.items) if (addressOf(item) === address) return item;
    return null;
  }

  // Where every visible item is each frame, by the card it is on (or its window), and how far it shows.
  function sample(): void {
    const now = Date.now() - probe.started;
    for (const entry of windows()) {
      for (const { item, opacity } of entry.items) {
        if (!isText(item) && !isImage(item) && !(isRect(item) && item.color.a > 0) && typeOf(item) !== "Glyph") continue;
        let frame = null;
        for (let at = item.parent; at && !frame; at = at.parent) if (typeOf(at) === "Card") frame = at;
        const place = frame && frame !== item ? item.mapToItem(frame, 0, 0) : item.mapToItem(null, 0, 0);
        let track = probe.tracks.get(item);
        if (!track) {
          track = { label: label(entry, item), window: entry.type, frames: [] };
          probe.tracks.set(item, track);
        }
        track.frames.push([now, place.x, place.y, item.width, item.height, opacity]);
      }
    }
    probe.samples++;
  }
  property int samples: 0

  // A track moves smoothly over several frames, or all at once; what moves back and forth, or snaps while others ease, is a jump.
  function analyse(): var {
    const problems = [];
    const moved = [];
    const all = Array.from(probe.tracks.values()).filter(track => track.frames.length === probe.samples && probe.samples > 2);
    // Each frame's step counts above a hair, so a slow fade moves; going back and forth takes a few px (or 0.06) each way.
    const props = [["x", 1, 0.1, 3], ["y", 2, 0.1, 3], ["width", 3, 0.1, 3], ["height", 4, 0.1, 3], ["opacity", 5, 0.001, 0.06]];
    const steps = (track, index, least) => {
      const out = [];
      for (let i = 1; i < track.frames.length; i++) {
        const delta = track.frames[i][index] - track.frames[i - 1][index];
        if (Math.abs(delta) > least) out.push({ at: i, delta, time: track.frames[i][0] });
      }
      return out;
    };
    const easing = new Set();
    for (const track of probe.tracks.values()) {
      for (const [name, index, least] of props) {
        const moves = steps(track, index, least);
        if (moves.length > 0 && Math.abs(track.frames[track.frames.length - 1][index] - track.frames[0][index]) > least) moved.push({ label: track.label, property: name, from: track.frames[0][index], to: track.frames[track.frames.length - 1][index], start: moves[0].time, end: moves[moves.length - 1].time });
      }
    }
    for (const track of all) {
      for (const [name, index, least, significant] of props) {
        const moves = steps(track, index, least);
        if (moves.length >= 3) easing.add(track.window);
        const forth = moves.filter(move => move.delta > 0).reduce((sum, move) => sum + move.delta, 0);
        const back = -moves.filter(move => move.delta < 0).reduce((sum, move) => sum + move.delta, 0);
        if (forth > significant && back > significant) problems.push(`${track.label}: its ${name} goes back and forth (+${forth.toFixed(1)}, -${back.toFixed(1)})`);
      }
    }
    for (const track of all) {
      if (!easing.has(track.window)) continue;
      for (const [name, index] of [["x", 1], ["y", 2]]) {
        const moves = steps(track, index, 0.5);
        const travel = moves.reduce((sum, move) => sum + Math.abs(move.delta), 0);
        if (moves.length === 1 && travel > 6) problems.push(`${track.label}: its ${name} snaps ${travel.toFixed(1)} px in one frame while the rest of its window eases`);
      }
    }
    return { problems, moved };
  }

  FrameAnimation {
    running: probe.recording
    onTriggered: probe.sample()
  }

  IpcHandler {
    target: "probe"

    function census(): string {
      return JSON.stringify(probe.census());
    }

    function areas(): string {
      return JSON.stringify({ scale: probe.scale, areas: probe.areas() });
    }

    function describe(address: string): string {
      return JSON.stringify(probe.describe(address));
    }

    function motion(on: bool): string {
      if (on) {
        probe.tracks = new Map();
        probe.samples = 0;
        probe.started = Date.now();
        probe.recording = true;
        return "{}";
      }
      probe.recording = false;
      probe.sample();
      return JSON.stringify(probe.analyse());
    }

    function state(): string {
      return JSON.stringify({
        panel: Panels.active,
        screens: Quickshell.screens.map(s => ({
          name: s.name,
          x: s.x,
          y: s.y,
          width: s.width,
          height: s.height,
          monitor: Hyprland.monitors.values.find(m => m.name === s.name)?.id ?? null
        })),
        focused: Hyprland.focusedMonitor?.name ?? null,
        monitors: Hyprland.monitors.values.map(m => ({
          id: m.id,
          name: m.name,
          workspace: m.activeWorkspace?.id ?? null
        })),
        workspaces: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => ({
          id: w.id,
          monitor: w.monitor?.name ?? null,
          // As the bar and the window switcher name it.
          label: WorkspaceOwners.label(w, w.monitor),
          windows: w.toplevels.values.length
        })),
        windows: Hyprland.toplevels.values.map(t => ({
          class: t.lastIpcObject?.class ?? null,
          monitor: t.monitor?.name ?? null,
          workspace: t.workspace?.id ?? null
        })),
        popups: Notifs.popups.map(e => ({
          id: e.notification?.id ?? null,
          summary: e.notification?.summary ?? null,
          screen: e.screen,
          hovered: e.hovered,
          waiting: e.waiting,
          shown: e.time.getTime(),
          remaining: e.remaining ?? null
        })),
        notifications: Notifs.entries.length,
        history: Notifs.entries.map(e => ({ app: Notifs.appKey(e), summary: e.notification?.summary ?? null, popup: e.popup, hovered: e.hovered, checked: e.checked, restored: e.restored ?? false, kept: Object.keys(e.kept ?? {}) })),
        historyFile: Quickshell.statePath("notification-history.json"),
        historyImages: History.images,
        dnd: Notifs.dnd,
        unchecked: Notifs.unchecked,
        volume: { percent: Volume.percent, muted: Volume.muted, output: Volume.devices.find(d => d.current)?.name ?? null },
        input: Osd.sourceName,
        osd: Osd.current ? Object.assign({ screen: Osd.screen }, Osd.current) : null,
        osdShown: Osd.serial,
        osdSettling: Osd.settling,
        brightness: Brightness.devices,
        caps: CapsLock.on,
        privacy: { mic: Privacy.mic, screen: Privacy.screenActive ? Privacy.screen : null, camera: Privacy.cameraActive ? Privacy.camera : null },
        caffeine: Caffeine.active,
        tray: SystemTray.items.values.filter(item => item.status !== Status.Passive).map(item => item.id),
        // The launcher's search field, or whichever text field is up.
        field: probe.windows().map(entry => entry.items.find(({ item }) => "cursorPosition" in item && "echoMode" in item)).find(found => found)?.item.text ?? null,
        problems: probe.census()
      });
    }
  }
}
