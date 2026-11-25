/* Round 1 of a motion board: how the control centre's toggle menus open, swap and move. Each mock is a live
   copy of the shell's card; go() drives a transition with the engine's tween/settle, so clicks mid-animation
   start from wherever it is. Picks: Unfold, Swap in place, Both at once, GNOME's 200 ms. */
const BOARD = {
  name: 'Toggle menu motion',
  slug: 'toggle-menus',
  round: 1,
  eyebrow: 'Control centre · toggle menus',
  headline: 'How a toggle menu opens, swaps and moves',
  footnote: "Inter stands in for Adwaita Sans and Material Symbols for the shell's MDI glyphs. Sizes, colours, radii and gaps are the shell's Theme at scale 1. Motion runs on the Web Animations API with each option's real duration; CSS cubic-béziers stand in for Qt's OutQuad, OutCubic and InOutCubic. Network and device names are made up."
};
const DECIDED = [
  "A menu still opens under its pill's row, one at a time, and pushes the rows below it down.",
  "Only the toggle menus' motion is in question: the control centre's own fade and slide, and rows coming and going inside an open menu, stay as they are.",
  "Today is GNOME 51's sequence at its 200 ms: the space eases open, then the menu fades in; a row's other menu fades out, then in; another row's opens as the old one fades and shuts."
];
const SCENARIOS = [SPEED];

/* ===== The control centre's data ===== */
const PILLS = {
  wired: { t: 'Wired', s: '1 Gb/s', i: 'settings_ethernet', on: true },
  wifi: { t: 'Wi-Fi', s: 'Kontor-5G', i: 'wifi', on: true, menu: true },
  vpn: { t: 'VPN', s: 'wg0', i: 'vpn_key', on: true, menu: true },
  bluetooth: { t: 'Bluetooth', s: 'WH-1000XM4', i: 'bluetooth', on: true, menu: true },
  night: { t: 'Night Light', s: '', i: 'nightlight', on: false, menu: true },
  caffeine: { t: 'Caffeine', s: '', i: 'coffee', on: false }
};
const ROWS = [['wired', 'wifi'], ['vpn', 'bluetooth'], ['night', 'caffeine']];
const rowOf = k => ROWS.findIndex(r => r.includes(k));
const lock = ms('lock', 16, 1, 'var(--m-dim)');
const sw = on => `<span class="sw ${on ? 'on' : ''}"><i></i></span>`;
const MENUS = {
  wifi: { title: 'Wi-Fi', icon: 'wifi', rows: [
    { i: 'wifi', t: 'Kontor-5G', strong: true, end: lock + ms('check', 16, 1, 'var(--m-accent)') },
    { i: 'wifi', t: 'Kontor-2G', end: lock },
    { i: 'network_wifi_3_bar', t: 'Pixel_7128', note: 'Saved', end: lock },
    { i: 'network_wifi_2_bar', t: 'NETGEAR-Guest' },
    { i: 'network_wifi_1_bar', t: 'DIRECT-roku-441', end: lock }
  ], foot: [['visibility_off', 'Connect to Hidden Network…'], ['settings', 'Network Settings']] },
  vpn: { title: 'VPN', icon: 'vpn_key', rows: [
    { i: 'vpn_key', t: 'wg0', end: sw(true) },
    { i: 'vpn_key', t: 'Office', end: sw(false) }
  ], foot: [['settings', 'Network Settings']] },
  bluetooth: { title: 'Bluetooth', icon: 'bluetooth', rows: [
    { i: 'headphones', t: 'WH-1000XM4', strong: true, note: '70 %', end: ms('battery_5_bar', 16, 1) + ms('bluetooth_connected', 16, 1, 'var(--m-accent)') },
    { i: 'mouse', t: 'MX Master 3', end: ms('bluetooth', 16, 1, 'var(--m-faint)') },
    { i: 'keyboard', t: 'Keychron K3', end: ms('bluetooth', 16, 1, 'var(--m-faint)') }
  ], foot: [['settings', 'Bluetooth Settings']] },
  night: { title: 'Night Light', icon: 'nightlight', count: '4000 K', slider: 0.45 }
};

/* ===== Renderers ===== */
function pill(scope, k, open) {
  const p = PILLS[k];
  return `<div class="pill ${p.on ? 'on' : ''} ${open ? 'open' : ''}" data-k="${k}"><span class="pmain">${ms(p.i, 16)}<span class="ptxt"><b>${p.t}</b>${p.s ? `<small>${p.s}</small>` : ''}</span></span>${p.menu ? `<button class="parrow" type="button" data-act="menu:${scope}:${k}" aria-label="${p.t} menu">${ms('chevron_right', 16)}</button>` : ''}</div>`;
}
function menuHTML(k) {
  const m = MENUS[k];
  const head = `<div class="mh"><span class="chip ${PILLS[k].on ? 'on' : ''}">${ms(m.icon, 16)}</span><b>${m.title}</b>${m.count ? `<span class="mcount">${m.count}</span>` : ''}</div>`;
  const body = m.slider !== undefined
    ? `<div class="mslider"><div class="trough"><i style="width:${m.slider * 100}%;background:var(--m-dim)"></i><b style="left:${m.slider * 100}%"></b></div></div>`
    : m.rows.map(r => `<div class="mrow ${r.strong ? 'strong' : ''}">${ms(r.i, 16)}<span class="mt">${r.t}</span>${r.note ? `<span class="mnote">${r.note}</span>` : ''}${r.end || ''}</div>`).join('');
  const foot = m.foot ? `<div class="msep"></div>${m.foot.map(([i, t]) => `<div class="mrow">${ms(i, 16)}<span class="mt">${t}</span></div>`).join('')}` : '';
  return `<div class="menu" data-key="${k}">${head}${body}${foot}</div>`;
}
function levels() {
  return `<div class="lv">${ms('volume_up', 16)}<div class="trough"><i style="width:64%"></i><b style="left:64%"></b></div><span class="lvarrow">${ms('chevron_right', 16)}</span></div>`;
}
const OPEN = { A: 'seq', B: 'unfold', C: 'reveal', D: 'drop' };
const SWAP = { A: 'seq', B: 'cross', C: 'slide', D: 'instant' };
const HAND = { A: 'together', B: 'quick', C: 'after' };
const MS = {};  // which menu each mock shows, kept across re-renders
function mock(scope) {
  const M = MS[scope] ??= { open: '' };
  const v = { open: OPEN[P('open')], swap: SWAP[P('swap')], hand: HAND[P('hand')], time: P('time') };
  const at = M.open ? rowOf(M.open) : -1;
  const rows = ROWS.map((r, i) => `<div class="prow">${r.map(k => pill(scope, k, M.open === k)).join('')}</div><div class="slot" style="height:${at === i ? 'auto' : '0px'}"><div class="slot-in">${at === i ? menuHTML(M.open) : ''}</div></div>`).join('');
  return `<div class="mock"><div class="tools"><button class="tbtn" type="button" data-act="play:${scope}">${ms('play_arrow', 16)}Play</button><button class="tbtn" type="button" data-act="fast:${scope}">${ms('bolt', 16)}Click fast</button><button class="tbtn" type="button" data-act="shut:${scope}">${ms('close', 16)}Close</button></div><div class="cc" data-mock="${scope}" data-v='${JSON.stringify(v)}' style="--sp:${S.speed}">${levels()}${rows}</div></div>`;
}

/* ===== Motion: the engine's tween and settle, with each option's real duration ===== */
const TIMES = { A: [150, 'outQuad'], B: [200, 'outQuad'], C: [280, 'outCubic'], D: [260, 'inOutCubic'] };
const leave = m => m.classList.add('leaving');
const opacity = el => Number(getComputedStyle(el).opacity);

async function openSlot(slot, key, o, alive) {
  const inner = slot.firstElementChild;
  const h0 = slot.getBoundingClientRect().height;
  inner.insertAdjacentHTML('beforeend', menuHTML(key));
  const m = inner.lastElementChild, h = 12 + m.offsetHeight, H = { height: h + 'px' };
  if (o.open === 'seq') {
    m.style.opacity = '0';
    await tween(slot, H, o.d * (1 - h0 / h), o.e);
    if (alive()) await tween(m, { opacity: '1' }, o.d, o.e);
  } else if (o.open === 'unfold') {
    m.style.opacity = '0';
    await Promise.all([tween(slot, H, o.d, o.e), tween(m, { opacity: '1' }, o.d, o.e)]);
  } else if (o.open === 'reveal') {
    await tween(slot, H, o.d, o.e);
  } else {
    m.style.transform = `translateY(${h0 - h}px)`;
    await Promise.all([tween(slot, H, o.d, o.e), tween(m, { transform: 'translateY(0px)' }, o.d, o.e)]);
  }
}
async function reopenSlot(slot, m, o, alive) {
  const H = { height: 12 + m.offsetHeight + 'px' };
  if (o.open === 'seq') {
    await tween(slot, H, o.d, o.e);
    if (alive()) await tween(m, { opacity: '1' }, o.d * (1 - opacity(m)), o.e);
  } else await Promise.all([tween(slot, H, o.d, o.e), tween(m, { opacity: '1', transform: 'translateY(0px)' }, o.d, o.e)]);
}
async function closeSlot(slot, m, o, alive) {
  const H = { height: '0px' };
  if (!m) return tween(slot, H, o.d, o.e);
  if (o.open === 'seq' && !o.together) {
    await tween(m, { opacity: '0' }, o.d * opacity(m), o.e);
    if (alive()) await tween(slot, H, o.d, o.e);
  } else if (o.open === 'seq' || o.open === 'unfold') {
    await Promise.all([tween(m, { opacity: '0' }, o.d, o.e), tween(slot, H, o.d, o.e)]);
  } else if (o.open === 'reveal') {
    await tween(slot, H, o.d, o.e);
  } else {
    await Promise.all([tween(slot, H, o.d, o.e), tween(m, { transform: `translateY(${-(12 + m.offsetHeight)}px)` }, o.d, o.e)]);
  }
  if (alive()) m.remove();
}
async function swapSlot(slot, old, key, o, alive) {
  const inner = slot.firstElementChild;
  const add = style => { inner.insertAdjacentHTML('beforeend', menuHTML(key)); const m = inner.lastElementChild; Object.assign(m.style, style); return m; };
  const height = m => ({ height: 12 + m.offsetHeight + 'px' });
  if (o.swap === 'seq') {
    leave(old);
    await tween(old, { opacity: '0' }, o.d * opacity(old), o.e);
    if (!alive()) return;
    old.remove();
    const m = add({ opacity: '0' });
    await Promise.all([tween(slot, height(m), o.d, o.e), tween(m, { opacity: '1' }, o.d, o.e)]);
    return;
  }
  leave(old);
  if (o.swap === 'cross') {
    const m = add({ opacity: '0' });
    await Promise.all([tween(old, { opacity: '0' }, o.d, o.e), tween(m, { opacity: '1' }, o.d, o.e), tween(slot, height(m), o.d, o.e)]);
  } else if (o.swap === 'slide') {
    const m = add({ transform: `translateX(${o.dir * 100}%)` });
    await Promise.all([tween(old, { transform: `translateX(${-o.dir * 100}%)` }, o.d, o.e), tween(m, { transform: 'translateX(0%)' }, o.d, o.e), tween(slot, height(m), o.d, o.e)]);
  } else {
    old.remove();
    await tween(slot, height(add({})), o.d, o.e);
  }
  if (alive()) old.remove();
}
function show(slot, key, o, alive) {
  const inner = slot.firstElementChild;
  // Whatever an interrupted swap left behind fades from where it is.
  for (const m of inner.querySelectorAll('.menu.leaving')) tween(m, { opacity: '0' }, o.d, o.e).then(() => { if (alive()) m.remove(); });
  const cur = [...inner.children].filter(m => !m.classList.contains('leaving')).pop();
  const h0 = slot.getBoundingClientRect().height;
  if (!key) return h0 < 0.5 && !cur ? Promise.resolve() : closeSlot(slot, cur, o, alive);
  if (cur && cur.dataset.key === key) return reopenSlot(slot, cur, o, alive);
  if (!cur || h0 < 0.5) { cur?.remove(); return openSlot(slot, key, o, alive); }
  return swapSlot(slot, cur, key, o, alive);
}
function go(scope, key) {
  const root = document.querySelector(`[data-mock="${scope}"]`);
  if (!root) return;
  const M = MS[scope], v = JSON.parse(root.dataset.v);
  const prev = M.open, next = key === prev ? '' : key;
  settle(root);
  M.open = next;
  root.querySelectorAll('.pill').forEach(p => p.classList.toggle('open', p.dataset.k === next));
  const alive = generation(scope);
  const [d, en] = TIMES[v.time], e = EASE[en];
  const target = next ? rowOf(next) : -1;
  const slots = [...root.querySelectorAll('.slot')];
  const row = ROWS[target] ?? [];
  const dir = prev && rowOf(prev) === target && row.indexOf(next) < row.indexOf(prev) ? -1 : 1;
  const base = { d, e, open: v.open, swap: v.swap, dir };
  const closing = slots.filter((s, i) => i !== target && (s.getBoundingClientRect().height > 0.5 || s.querySelector('.menu')));
  const opening = target >= 0 ? slots[target] : null;
  const handing = opening !== null && closing.length > 0;
  const shut = { ...base, together: handing && v.hand !== 'after', d: handing && v.hand === 'quick' ? d / 2 : d };
  const closes = closing.map(s => show(s, '', shut, alive));
  if (!opening) return;
  if (handing && v.hand === 'after') Promise.all(closes).then(() => { if (alive()) show(opening, next, base, alive); });
  else show(opening, next, base, alive);
}
async function play(scope, gap, keys) {
  const alive = generation('play-' + scope);
  if (MS[scope]?.open) { go(scope, ''); await wait(900 * speed()); }
  for (const k of keys) {
    if (!alive()) return;
    go(scope, k);
    await wait(gap * speed());
  }
}

/* ===== The questions ===== */
const SECTIONS = [
  { group: 'One menu', id: 'open', title: 'A menu opening and closing',
    q: "Click a pill's arrow to open its menu and again to close it; Play runs Wi-Fi → VPN → Bluetooth → VPN → Night Light → closed, Click fast hops four menus 160 ms apart. Each mock switches and times as your other picks say.",
    opts: [
      { k: 'A', name: 'Grow, then fade (today)', desc: "The space eases open, then the menu fades in; closing fades it out, then shuts the space. GNOME's two steps, so twice the time." },
      { k: 'B', name: 'Unfold', desc: 'The space and the menu move as one: it fades in as it grows and out as it shrinks.', rec: true },
      { k: 'C', name: 'Reveal', desc: 'No fade at all: the growing edge uncovers the menu, which sits still.' },
      { k: 'D', name: 'Drawer', desc: 'The menu slides down out from under its row as the space opens, and back up under it as it shuts.' }
    ], render: k => W({ open: k }, () => mock('open-' + k)) },
  { group: 'Switching', id: 'swap', title: "Swapping for the row's other menu",
    q: "VPN and Bluetooth share a row, so their menus share one place. Open VPN, then click Bluetooth's arrow, and back.",
    opts: [
      { k: 'A', name: 'Out, then in (today)', desc: 'The old menu fades out, then the new one fades in as the space eases to its height: the place empties for a moment.' },
      { k: 'B', name: 'Crossfade', desc: 'The new menu fades in over the old one as it fades out, while the space eases to the new height; the place is never empty.', rec: true },
      { k: 'C', name: 'Slide across', desc: 'The old menu slides away toward the pill you left, the new one in from the side of the pill you clicked, while the space eases.' },
      { k: 'D', name: 'Swap in place', desc: 'The content changes at once, no fade; only the height eases.' }
    ], render: k => W({ swap: k }, () => mock('swap-' + k)) },
  { group: 'Switching', id: 'hand', title: "Moving to another row's menu",
    q: 'Open Wi-Fi, then VPN or Night Light: one place shuts while another opens.',
    opts: [
      { k: 'A', name: 'Both at once (today)', desc: "The old menu shuts while the new one opens over the same time, so the card's height goes one way." },
      { k: 'B', name: 'Quick hand-off', desc: 'The old menu shuts in half the time as the new one opens, so the eye goes to the new one at once.', rec: true },
      { k: 'C', name: 'One after the other', desc: 'The old menu closes completely, then the new one opens: one thing moving at a time, but twice as long.' }
    ], render: k => W({ hand: k }, () => mock('hand-' + k)) },
  { group: 'Feel', id: 'time', title: 'Timing and easing',
    q: 'The height and the fade share these. Slow ×3 in the bar above makes the curves easy to compare.',
    opts: [
      { k: 'A', name: 'Brisk', desc: "150 ms, ease-out quad: the popover's own." },
      { k: 'B', name: 'GNOME (today)', desc: "200 ms, ease-out quad: half of Shell's POPUP_ANIMATION_TIME." },
      { k: 'C', name: 'Soft', desc: '280 ms, ease-out cubic: quick to start, a long gentle landing.', rec: true },
      { k: 'D', name: 'Smooth', desc: '260 ms, ease-in-out cubic: starts and lands gently, quickest in the middle.' }
    ], render: k => W({ time: k }, () => mock('time-' + k)) }
];
function renderTogether() { return `<div class="opt"><div class="stage">${mock('asm')}</div></div>`; }
function onAct(act, x, y) {
  if (act === 'menu') { go(x, y); return false; }
  if (act === 'shut') { generation('play-' + x); go(x, ''); return false; }
  if (act === 'play') { play(x, 1100, ['wifi', 'vpn', 'bluetooth', 'vpn', 'night', '']); return false; }
  if (act === 'fast') { play(x, 160, ['wifi', 'vpn', 'bluetooth', 'night', 'bluetooth']); return false; }
  return false;
}

