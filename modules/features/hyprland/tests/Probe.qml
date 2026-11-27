import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.bar
import qs.controls
import qs.center
import qs.common
import qs.notifications
import qs.osd
import qs.weather

// qs-test adds this to the session's copy of the shell only: `qst state` is its `state`.
Scope {
  id: probe

  // Sizes and corners that are not a role's, by the type that draws them.
  readonly property var ownShapes: ({
    BatteryGlyph: "a cell drawn to its own scale",
    LayoutDiagram: "outputs drawn to scale",
    PowerMenu: "the power tiles' large squircles",
    TrayMenu: "libadwaita's check box"
  })

  readonly property string scale: Quickshell.env("QT_SCALE_FACTOR") ?? "1"

  property bool recording: false
  property var tracks: null
  property real started: 0
  // Each flip, so a key held on its switch shows how often it acted; from the first state read, as reading Notifs creates it, and a shell that is to quit never may.
  property int dndFlips: 0
  property bool read: false

  Connections {
    target: probe.read ? Notifs : null

    function onDndChanged(): void {
      probe.dndFlips++;
    }
  }

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
      if (color.a < 1) for (const base of [Theme.popoverBg, Theme.panelBg, Theme.cardBg, Theme.messageBg]) allowed.add(key(Qt.tint(base, color)));
    }
    allowedColors = allowed;
  }

  // Theme's, or the media card's from its cover (Theme.cover).
  function themed(color: color): bool {
    return allowedColors.has(key(color)) || Object.values(Media.tint ?? {}).includes(String(color));
  }

  // The open center's media art as drawn, its width and its top in the window; null with none.
  function mediaArt(): var {
    for (const entry of windows()) for (const { item } of entry.items) if (item.objectName === "media:art") return { width: Math.round(item.width), y: Math.round(item.mapToItem(null, 0, 0).y) };
    return null;
  }

  // A line of the open center's media card: whether it slides, how far it is cut short, and where its text is.
  function mediaLine(name: string): var {
    for (const entry of windows()) for (const { item } of entry.items) if (item.objectName === name) return { rolling: item.rolling, overflow: Math.round(item.overflow), x: Math.round(item.children[0].x) };
    return null;
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
    // What a test clicks by name: the control centre names its pills and rows.
    const named = item.objectName || item.parent?.objectName || "";
    const name = named ? `:${named}` : "";
    return `${entry.type}/${typeOf(item)}${name}${text}`;
  }

  function luminance(color: color): real {
    const linear = channel => channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
  }

  function over(top: color, bottom: color): color {
    return Qt.rgba(top.r * top.a + bottom.r * (1 - top.a), top.g * top.a + bottom.g * (1 - top.a), top.b * top.a + bottom.b * (1 - top.a), 1);
  }

  // What lies behind an item: its window's colour, or the panel's black where the window is see-through, under its filled ancestors.
  function behind(entry: var, item: var): color {
    const fills = [];
    for (let at = item.parent; at; at = at.parent) if (isRect(at) && at.color.a > 0) fills.unshift(at);
    let color = entry.window.color.a > 0.99 ? entry.window.color : Theme.panelBg;
    for (const fill of fills) color = over(fill.color, color);
    return color;
  }

  // Where an item's glyphs are drawn in its window, cut to what its clipping ancestors show.
  function inked(item: var): var {
    const align = item.effectiveHorizontalAlignment;
    const x = align === Text.AlignRight ? item.width - item.paintedWidth : align === Text.AlignHCenter ? (item.width - item.paintedWidth) / 2 : 0;
    const y = item.verticalAlignment === Text.AlignBottom ? item.height - item.paintedHeight : item.verticalAlignment === Text.AlignVCenter ? (item.height - item.paintedHeight) / 2 : 0;
    // A line's box holds its ascent and leading above the glyphs, which a large one lays over the line above.
    const room = item.paintedHeight * 0.2;
    // Both corners mapped, as a window drawn scaled down (the shortcuts window on a small screen) scales its items too.
    const from = item.mapToItem(null, x, y + room);
    const to = item.mapToItem(null, x + item.paintedWidth, y + item.paintedHeight - room);
    let box = { left: from.x, top: from.y, right: to.x, bottom: to.y };
    for (let clip = item.parent; clip; clip = clip.parent) {
      if (!clip.clip) continue;
      const near = clip.mapToItem(null, 0, 0);
      const far = clip.mapToItem(null, clip.width, clip.height);
      box = { left: Math.max(box.left, near.x), top: Math.max(box.top, near.y), right: Math.min(box.right, far.x), bottom: Math.min(box.bottom, far.y) };
    }
    return box;
  }

  // Wholly outside a clipping ancestor, a list's row scrolled away (or one a list is still laying out there): nobody sees it.
  function clippedAway(item: var): bool {
    for (let at = item.parent; at; at = at.parent) {
      if (!at.clip) continue;
      const box = item.mapToItem(at, 0, 0, Math.max(1, item.width), Math.max(1, item.height));
      if (box.x + box.width <= 0 || box.y + box.height <= 0 || box.x >= at.width || box.y >= at.height) return true;
    }
    return false;
  }

  // Images loading, by item, since when: one that never finishes is a picture that never comes.
  property var loading: new Map()

  // What should never be on screen, in whatever state the shell is in.
  function census(): var {
    const problems = [];
    const loading = new Map();
    const now = Date.now();
    for (const entry of windows()) {
      // Text drawn over other text: a crowded bar running into its clock, a label under a badge.
      const texts = entry.items.filter(({ item, opacity }) => isText(item) && String(item.text).trim() !== "" && opacity > 0.99 && !(entry.type in ownShapes || ancestorTypes(item).some(name => name in ownShapes))).map(({ item }) => ({ item, box: inked(item) }));
      for (let i = 0; i < texts.length; i++) {
        for (let j = i + 1; j < texts.length; j++) {
          const a = texts[i].box;
          const b = texts[j].box;
          if (Math.min(a.right, b.right) - Math.max(a.left, b.left) > 3 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 3) problems.push(`${label(entry, texts[i].item)} and ${label(entry, texts[j].item)} are drawn over each other`);
        }
      }
      const width = entry.window.width;
      const height = entry.window.height;
      if (!("exclusionMode" in entry.window)) problems.push(`${entry.type} is not a layer surface: a popup window lands off on any monitor not at x 0`);
      for (const { item, opacity } of entry.items) {
        if (clippedAway(item)) continue;
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
          if (!themed(item.color)) problems.push(`${label(entry, item)} is coloured ${item.color}, which is not Theme's`);
          // What a missing property or a bad number reads as once it reaches a label.
          if (/\b(undefined|NaN)\b|\[object |Invalid Date/.test(String(item.text))) problems.push(`${label(entry, item)} shows a value that is not there`);
        } else if (isImage(item)) {
          const source = String(item.source);
          if (source === "") problems.push(`${label(entry, item)} is shown without a source`);
          else if (item.status === Image.Error) problems.push(`${label(entry, item)} failed to load ${source}`);
          else if (item.status === Image.Loading) {
            loading.set(item, probe.loading.get(item) ?? now);
            if (now - loading.get(item) > 5000) problems.push(`${label(entry, item)} has been loading ${source} for ${Math.round((now - loading.get(item)) / 1000)} s`);
          }
        } else if (isRect(item) && (item.color.a > 0 || item.border.width > 0)) {
          const radius = item.radius;
          const half = Math.min(item.width, item.height) / 2;
          const inherited = item.parent && isRect(item.parent) && item.parent.radius === radius;
          const roles = [0, Theme.keycapRadius, Theme.workspaceRadius, Theme.baseRadius, Theme.menuItemRadius, Theme.cardRadius, Theme.tileRadius, Theme.messageRadius, Theme.popoverRadius, Theme.toggleMenuRadius, Theme.dateMenuRadius, Theme.quickSettingsRadius];
          if (!own && !inherited && !roles.includes(radius) && Math.abs(radius - half) > 0.6) problems.push(`${label(entry, item)} has a radius of ${radius}: neither Theme's nor half its size`);
          const behavior = ProbeWindows.colorBehaviors.get(item);
          const shownColor = behavior?.animation?.running ? behavior.targetValue : item.color;
          if (!own && shownColor.a > 0 && !themed(shownColor)) problems.push(`${label(entry, item)} is coloured ${shownColor}, which is not Theme's`);
          if (!own && item.border.width > 0 && !themed(item.border.color)) problems.push(`${label(entry, item)} has a border coloured ${item.border.color}, which is not Theme's`);
        } else if (isMouseArea(item) && !item.enabled && item.cursorShape === Qt.PointingHandCursor) {
          problems.push(`${label(entry, item)} is disabled but still sets a pointing hand`);
        }
        if (type === "Card") {
          const at = item.mapToItem(null, 0, 0);
          if (at.x < -0.5 || at.y < -0.5 || at.x + item.width > width + 0.5 || at.y + item.height > height + 0.5) problems.push(`${label(entry, item)} at ${Math.round(at.x)},${Math.round(at.y)} ${Math.round(item.width)}x${Math.round(item.height)} runs off its ${Math.round(width)}x${Math.round(height)} window`);
        }
      }
    }
    probe.loading = loading;
    return problems;
  }

  // Every mouse area on screen, with its middle in layout coordinates, for the cursor sweep; qs-test places each window by Hyprland's layers.
  function areas(): var {
    const found = [];
    for (const entry of windows()) {
      for (const { item } of entry.items) {
        // A tooltip's hover, on its owner or not, is no place to click, and would only double its control.
        const hovers = !("owner" in item && "shown" in item) && Array.from(item.data ?? []).some(child => child && child.objectName !== "tooltip" && "cursorShape" in child && "hovered" in child && "point" in child && !("width" in child));
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

  Component {
    id: churnCard

    Card {
      width: 100
      height: 50
    }
  }

  // Started again from its own exit, as callers chain runs.
  Command {
    id: chained

    property var next: []

    onDone: {
      if (chained.next.length === 0) return;
      chained.command = chained.next;
      chained.next = [];
      chained.running = true;
    }
  }

  // Only in the session's copy, so the live shell carries no test hooks.
  IpcHandler {
    target: "bar"

    // COUNT outputs, the one in use well down the list and some with hostile names, as no real sound server would have.
    function fakeOutputs(count: int): void {
      const names = Array.from({ length: count }, (_, i) => i === 3 ? "A sink with a name a kilobyte long ".repeat(30) : i === 5 ? "Right\u202eto left\nand two lines\u200b" : `Output ${i + 1}`);
      Volume.fake = { volume: 0.64, muted: false, current: Math.floor(count * 0.6), devices: names };
    }

    function realVolume(): void {
      Volume.fake = null;
    }
  }

  // `state` without a qs process per call, which costs most of a snapshot: a GET answered over HTTP, which curl speaks on a socket.
  SocketServer {
    active: true
    path: `${Quickshell.env("QS_TEST_SHELL")}/probe.sock`
    handler: Socket {
      id: client

      parser: SplitParser {
        onRead: line => {
          if (!line.startsWith("GET ")) return;
          client.write(`HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n${answers.state()}\n`);
          client.flush();
          client.connected = false;
        }
      }
    }
  }

  IpcHandler {
    id: answers

    target: "probe"

    function census(): string {
      return JSON.stringify(probe.census());
    }

    // COUNT Cards made and destroyed: what each leaves behind shows in the process's memory.
    function churn(count: int): string {
      for (let i = 0; i < count; i++) churnCard.createObject(null).destroy();
      gc();
      return "done";
    }

    // FIRST, then from its exit THEN if any, one Command.
    function chain(first: string, then: string): string {
      chained.next = then === "" ? [] : [then];
      chained.command = [first];
      chained.running = true;
      return "started";
    }

    // PROGRAM launched as the shell launches apps.
    function launch(program: string): string {
      Detached.run([program], "");
      return "launched";
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
      probe.read = true;
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
          summary: e.summary ?? null,
          screen: e.screen,
          waiting: e.waiting,
          shown: e.time.getTime(),
          remaining: e.remaining ?? null
        })),
        notifications: Notifs.entries.length,
        // What the keyboard is on in a window that has it, by label, and whether its ring shows.
        focused: (() => { let found = null; for (const entry of probe.windows()) for (const { item } of entry.items) if (item.activeFocus && "activeFocusOnTab" in item && item.activeFocusOnTab) found = probe.label(entry, item); return found; })(),
        // A focused row's title, which its label leaves out.
        focusedTitle: (() => { let found = null; for (const entry of probe.windows()) for (const { item } of entry.items) if (item.activeFocus && item.activeFocusOnTab && typeof item.title === "string") found = item.title; return found; })(),
        ring: Panels.keyboard,
        // Every piece showing its hover, by label: one left lit after the pointer has gone is the stuck grey.
        hovered: (() => { const found = []; for (const entry of probe.windows()) for (const { item } of entry.items) if (item.hovered === true && "color" in item) found.push(probe.label(entry, item)); return found; })(),
        tooltip: Tooltips.shown ? { text: Tooltips.text, screen: Tooltips.screen, at: [Math.round(Tooltips.target.x + Tooltips.target.width / 2), Math.round(Tooltips.target.y + Tooltips.target.height / 2)] } : null,
        tooltipPending: Tooltips.pending ? Tooltips.pendingText : null,
        history: Notifs.entries.map(e => ({ uid: e.uid, time: e.time.getTime(), app: Notifs.appKey(e), summary: e.summary ?? null, body: e.body, popup: e.popup, checked: e.checked, restored: e.restored ?? false, image: e.image || null, kept: Object.keys(e.kept ?? {}) })),
        historyFile: Quickshell.statePath("notification-history.json"),
        historyLoaded: History.loaded,
        // What the shell takes the file to hold, by count; null once a save failed, -1 for a file it could not read.
        historySaved: (() => {
          try {
            return History.written === "" ? null : (JSON.parse(History.written).notifications ?? []).length;
          } catch (error) {
            return -1;
          }
        })(),
        historyImages: History.images,
        // What the popups and the center draw, by source, loaded.
        notificationPictures: probe.windows().filter(entry => ["NotificationPopups", "NotificationCenter"].includes(entry.type)).reduce((found, entry) => [...found, ...entry.items.filter(({ item }) => probe.isImage(item) && item.status === Image.Ready).map(({ item }) => String(item.source))], []),
        // The shell's minute, as the bar's clock and the calendar take it, and its cache dir.
        now: Qt.formatDateTime(Time.now, "yyyy-MM-dd HH:mm"),
        cache: Quickshell.cachePath(""),
        dnd: Notifs.dnd,
        dndFlips: probe.dndFlips,
        unchecked: Notifs.unchecked,
        volume: { percent: Volume.percent, muted: Volume.muted, output: Volume.devices.find(d => d.current)?.name ?? null },
        input: Microphone.name,
        microphone: { muted: Microphone.muted, input: Microphone.name || null, inputs: Microphone.devices.map(d => d.name) },
        osd: Osd.current ? Object.assign({ screen: Osd.screen }, Osd.current) : null,
        osdShown: Osd.serial,
        osdSettling: Osd.settling,
        brightness: Brightness.devices,
        caps: CapsLock.on,
        caffeine: Caffeine.active,
        // The machine, and whether the control centre's header shows it.
        machine: { logo: Machine.logo, icon: Machine.icon !== "", hostname: Machine.hostname, uptime: Machine.uptime, header: probe.windows().find(entry => entry.type === "ControlsPanel")?.items.find(({ item }) => "bare" in item)?.item.bare ?? null },
        privacy: { mic: Privacy.mic, screen: Privacy.screenActive ? Privacy.screen : null, camera: Privacy.cameraActive ? Privacy.camera : null },
        controls: {
          menu: Controls.menu,
          // The open menu: its count, and the rows its filter leaves, a few by title.
          open: (menu => menu ? { count: menu.count, rows: menu.shown.length, first: menu.shown.slice(0, 5).map(row => row.title), sound: menu.key === "sound" ? menu.shown.map(row => row.heading ? `# ${row.title}` : `${row.title} (${row.kind})`) : null } : null)(probe.windows().find(entry => entry.type === "ControlsPanel")?.items.find(({ item }) => "filtering" in item && "shown" in item)?.item ?? null),
          toggles: Controls.toggles.map(t => ({ key: t.key, subtitle: t.subtitle, on: t.on, unavailable: t.unavailable ?? false })),
          // The open centre's In Use pills, as drawn.
          inUse: (probe.windows().find(entry => entry.type === "ControlsPanel")?.items ?? []).filter(({ item }) => String(item.toggle?.key ?? "").startsWith("inuse:")).map(({ item }) => item.toggle.subtitle),
          network: { present: Net.present, running: Net.running, wifi: Net.wifis.length > 0, cards: Net.wifis.map(d => d.name), wifiOn: Net.wifiOn, scanning: Net.scanning, connected: Net.connected?.name ?? null, networks: Net.networks.map(n => n.name), known: Net.networks.filter(n => n.known).map(n => n.name), asking: Net.asking || null, askingOn: Net.askingOn || null, hidden: Net.hidden ? { ssid: Net.hidden.ssid, error: Net.hidden.error || null, busy: Net.hidden.busy } : null, askError: Net.askError || null, created: Net.created, failures: Net.failures, portal: Net.portal, limited: Net.limited, signIn: Net.signInOffered, relaxed: Net.relaxed || null, wired: Net.wired.map(d => ({ name: d.name, connected: d.connected, link: d.hasLink })) },
          vpns: Net.vpns.map(v => ({ name: v.name, active: v.active, busy: Net.busy(v.uuid) || null })),
          vpnAsking: Net.vpnAsking || null,
          bluetooth: { present: BluetoothDevices.present, on: BluetoothDevices.on, scanning: BluetoothDevices.scanning, devices: BluetoothDevices.devices.map(d => ({ name: d.name, address: d.address, paired: d.paired, connected: d.connected, trusted: d.trusted, note: BluetoothDevices.note(d) || null, battery: d.batteryAvailable ? Math.round(d.battery * 100) : null })) },
          night: { present: NightLight.present, on: NightLight.on, temperature: NightLight.temperature },
          media: Media.player ? { title: Media.title, artist: Media.artist, playing: Media.player.isPlaying, identity: Media.player.identity, position: Math.round(Media.player.position), length: Math.round(Media.length), pinned: Media.pinned !== "" ? Media.player.identity : null, switcher: Media.switchable ? Media.live.map(p => p.identity) : [], tint: Media.tint, art: probe.mediaArt()?.width ?? null, artY: probe.mediaArt()?.y ?? null, titleLine: probe.mediaLine("media:title"), artistLine: probe.mediaLine("media:artist") } : null
        },
        tray: SystemTray.items.values.filter(item => item.status !== Status.Passive).map(item => item.id),
        // Each bar's status button, what it shows by name, the glyphs drawn at full opacity, and its battery.
        status: probe.windows().filter(entry => entry.type === "BarWindow").map(entry => ({ screen: entry.screen, glyphs: entry.items.find(({ item }) => "glyphs" in item && "panel" in item)?.item.glyphs.map(glyph => glyph.name) ?? [], opaque: entry.items.filter(({ item, opacity }) => "leaving" in item && "look" in item && opacity > 0.99).map(({ item }) => item.modelData.name), battery: Power.present ? Power.percent : null })),
        // The screens whose clock shows pressed, as its center is open.
        clocks: probe.windows().filter(entry => entry.type === "BarWindow" && entry.items.some(({ item }) => "screenName" in item && "checked" in item && item.checked)).map(entry => entry.screen),
        // Every slider on screen by name, with its range: past 1 while it reaches beyond 100 %.
        sliders: [].concat(...probe.windows().map(entry => entry.items.filter(({ item }) => "heldMaximum" in item).map(({ item }) => ({ name: item.objectName, value: item.value, span: item.span })))),
        // The center's groups as drawn, top to bottom: each one's lines in its order, and whether expanded.
        center: [].concat(...probe.windows().filter(entry => entry.type === "NotificationCenter").map(entry => entry.items.filter(({ item }) => "ordered" in item && "unfolded" in item).map(({ item }) => ({ app: item.newest ? Notifs.appKey(item.newest) : null, y: Math.round(item.y), slid: Math.round(item.slid), expanded: item.expanded, lines: item.ordered.map(e => ({ summary: e.summary, critical: e.critical })) })))),
        // Action rows opened past their first two (More), in the center's cards.
        centerMore: [].concat(...probe.windows().filter(entry => entry.type === "NotificationCenter").map(entry => entry.items.filter(({ item }) => "moreOpen" in item && item.moreOpen))).length,
        trays: probe.windows().filter(entry => entry.type === "BarWindow").map(entry => {
          const tray = entry.items.find(({ item }) => "menuPanel" in item && "menuAnchor" in item)?.item;
          return { screen: entry.screen, shown: tray?.visible ?? false, expanded: tray?.expanded ?? false, more: tray?.more ?? 0, width: Math.round(tray?.implicitWidth ?? 0), scrolls: tray?.scrolls ?? false, offset: Math.round(tray?.offset ?? 0), items: tray ? tray.items.map(item => item.id) : [] };
        }),
        // The tray menu up: its open submenus by label and the row the keyboard is on.
        trayMenu: (menu => menu ? { path: menu.path, keyed: menu.keyed, selected: menu.level(menu.path.length)?.entries[menu.row]?.text ?? null, scrolled: Math.round(menu.level(menu.path.length)?.offset ?? 0) } : null)(probe.windows().find(entry => entry.type === "TrayMenu")?.window ?? null),
        // The launcher's first ten results by title, best first.
        results: (probe.windows().map(entry => entry.items.find(({ item }) => "results" in item && "query" in item && "mode" in item)).find(found => found)?.item.results ?? []).slice(0, 10).map(row => row.title ?? row.key ?? null),
        // The launcher's selected row by key, which a retitled window keeps.
        selected: (probe.windows().map(entry => entry.items.find(({ item }) => "results" in item && "query" in item && "mode" in item)).find(found => found)?.item.current?.key ?? null),
        // The text field being typed into, or else the first one up: the launcher's search.
        field: (probe.windows().map(entry => entry.items.find(({ item }) => "cursorPosition" in item && "echoMode" in item && item.activeFocus)).find(found => found) ?? probe.windows().map(entry => entry.items.find(({ item }) => "cursorPosition" in item && "echoMode" in item)).find(found => found))?.item.text ?? null,
        // The forecast the center shows: how many hours, the first symbol, and the place.
        weather: { place: Weather.place, hours: Weather.hours.length, now: Weather.now?.symbol ?? null },
        problems: probe.census()
      });
    }
  }
}
