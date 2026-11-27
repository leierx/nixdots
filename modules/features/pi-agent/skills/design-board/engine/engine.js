/* The board engine: picks and notes in localStorage, the scenario bar, Together, the prompt and the dock.
   board.js (loaded after this) defines BOARD, DECIDED, SECTIONS, renderTogether and onAct, and may add
   SCENARIOS, NEXT and scenario keys on S. Nothing here needs editing for a board. */

const S = { speed: '1', picks: {}, notes: {}, overall: '', next: 'round' };

/* Overrides: a section renders its option k with W({ id: k }, fn); renderers read picks through P(id),
   so one option's mock shows the user's other picks around it, and Together shows them all. */
let OVR = {};
function W(ovr, fn) { const o = OVR; OVR = { ...o, ...ovr }; try { return fn(); } finally { OVR = o; } }
const DEF = {};
function P(id) { return OVR[id] ?? S.picks[id] ?? DEF[id]; }
const ms = (name, size = 18, fill = 1, color = '') => `<span class="ms" style="font-size:${size}px;font-variation-settings:'FILL' ${fill},'wght' 400,'opsz' ${Math.min(48, Math.max(20, size))};${color ? 'color:' + color : ''}">${name}</span>`;

/* ===== Motion kit, for questions about animation ===== */
// Qt / GNOME (Clutter) easing names as CSS curves.
const EASE = {
  linear: 'linear',
  outQuad: 'cubic-bezier(.5,1,.89,1)', inQuad: 'cubic-bezier(.11,0,.5,0)', inOutQuad: 'cubic-bezier(.45,0,.55,1)',
  outCubic: 'cubic-bezier(.33,1,.68,1)', inCubic: 'cubic-bezier(.32,0,.67,0)', inOutCubic: 'cubic-bezier(.65,0,.35,1)',
  outQuart: 'cubic-bezier(.25,1,.5,1)', outExpo: 'cubic-bezier(.16,1,.3,1)', outBack: 'cubic-bezier(.34,1.56,.64,1)'
};
// Add SPEED to SCENARIOS to slow every tween down for comparing curves.
const SPEED = ['Speed', 'speed', [['1', 'Real time'], ['3', 'Slow ×3'], ['8', 'Slow ×8']]];
const speed = () => Number(S.speed) || 1;
const wait = t => new Promise(r => setTimeout(r, t));
// Animates from wherever el is now (mid-animation too, after settle) to `to`, leaving `to` set when done.
function tween(el, to, d, ease = EASE.outQuad) {
  const cs = getComputedStyle(el), from = {};
  for (const k in to) from[k] = k === 'height' ? el.getBoundingClientRect().height + 'px' : k === 'width' ? el.getBoundingClientRect().width + 'px' : cs[k];
  Object.assign(el.style, to);
  if (d <= 0) return Promise.resolve();
  return el.animate([from, to], { duration: d * speed(), easing: ease, fill: 'backwards' }).finished.catch(() => {});
}
// Freezes every tween under root where it is, so the next one starts from there; CSS transitions (hover, a chevron) are left alone, as committing them pins their value.
function settle(root) {
  for (const a of root.getAnimations({ subtree: true })) {
    if (a instanceof CSSTransition) continue;
    try { a.commitStyles(); } catch (e) {}
    a.cancel();
  }
}
// One running sequence per mock: start() bumps the generation, alive() says whether this one still owns the mock.
const GEN = {};
function generation(scope) { const g = GEN[scope] = (GEN[scope] || 0) + 1; return () => GEN[scope] === g; }

/* ===== Boot ===== */
const DEFAULT_NEXT = {
  round: ['Next round', 'Next: draft the next round on the same board from these picks, working my notes in, and keep going until I say implement.'],
  shots: ['Shoot it real', 'Next: build these picks in a scratch copy and screenshot them in the real environment so I can confirm.'],
  impl: ['Implement', 'Next: implement these picks, test them, commit, push and deploy.']
};
const next = () => (typeof NEXT !== 'undefined' ? NEXT : DEFAULT_NEXT);
const nextKey = k => (Object.hasOwn(next(), k) ? k : Object.keys(next())[0]);
const scenarios = () => (typeof SCENARIOS !== 'undefined' ? SCENARIOS : []);
const store = () => `design-board-${BOARD.slug}-r${BOARD.round}`;

function save() { try { localStorage.setItem(store(), JSON.stringify({ picks: S.picks, notes: S.notes, overall: S.overall, next: S.next })); } catch (e) {} }
function renderScen() {
  const el = document.getElementById('scen');
  el.hidden = scenarios().length === 0;
  el.innerHTML = scenarios().map(([l, key, vals]) => `<span class="grp"><span class="lab">${l}</span>${vals.map(([v, t]) => {
    const on = String(S[key]) === v;
    return `<button class="chipbtn ${on ? 'on' : ''}" type="button" data-scen="${key}:${v}" aria-pressed="${on}">${t}</button>`;
  }).join('')}</span>`).join('');
}
function buildBoard() {
  let html = '', group = '';
  for (const s of SECTIONS) {
    if (s.group !== group) {
      group = s.group;
      const n = SECTIONS.filter(x => x.group === group).length;
      html += `<div class="grouphead"><span class="eyebrow">${n} question${n === 1 ? '' : 's'}</span><h2>${group}</h2></div>`;
    }
    html += `<section class="sec" id="s-${s.id}"><header><h2>${s.title}</h2><p>${s.q}</p></header><div class="opts ${s.cls || ''}" id="o-${s.id}"></div><label class="note" for="n-${s.id}"><span>Notes on ${s.title.charAt(0).toLowerCase() + s.title.slice(1)}</span><textarea id="n-${s.id}" rows="2" placeholder="Tweak the pick, mix two, or say what is missing"></textarea></label></section>`;
  }
  document.getElementById('board').innerHTML = html;
  for (const s of SECTIONS) {
    const ta = document.getElementById('n-' + s.id);
    ta.value = S.notes[s.id] || '';
    ta.addEventListener('input', () => { S.notes[s.id] = ta.value; save(); updatePrompt(); });
  }
  const ov = document.getElementById('overall');
  ov.value = S.overall;
  ov.addEventListener('input', () => { S.overall = ov.value; save(); updatePrompt(); });
  document.getElementById('decided').innerHTML = DECIDED.map(d => `<li>${d}</li>`).join('');
}
function renderSection(s) {
  document.getElementById('o-' + s.id).innerHTML = s.opts.map(o => {
    const picked = S.picks[s.id] === o.k;
    return `<article class="opt ${picked ? 'picked' : ''}"><div class="stage ${s.stage || ''}">${s.render(o.k)}</div><button class="pickbtn" type="button" data-pick="${s.id}:${o.k}" aria-pressed="${picked}"><span class="letter">${o.k}</span><span><b>${o.name}</b>${o.rec ? '<em class="rec">my pick</em>' : ''}<p>${o.desc}</p></span><span class="state">${picked ? 'Picked' : 'Pick'}</span></button></article>`;
  }).join('');
}
function renderAll() {
  renderScen();
  SECTIONS.forEach(renderSection);
  document.getElementById('together').innerHTML = renderTogether();
  updatePrompt();
}
function promptText() {
  const L = [`${BOARD.name}: my picks, round ${BOARD.round}.`, '', 'Already decided:'];
  DECIDED.forEach(d => L.push('- ' + d.replace(/<[^>]+>/g, '')));
  let group = '';
  for (const s of SECTIONS) {
    if (s.group !== group) { group = s.group; L.push('', group + ':'); }
    const k = S.picks[s.id], o = s.opts.find(x => x.k === k);
    L.push(`- ${s.title}: ${o ? `${k}, "${o.name}" (${o.desc})` : `no pick; use your recommendation (${DEF[s.id]})`}`);
    const n = (S.notes[s.id] || '').trim();
    if (n) L.push(`  Note: ${n}`);
  }
  if (S.overall.trim()) L.push('', 'Overall: ' + S.overall.trim());
  L.push('', next()[S.next][1]);
  return L.join('\n');
}
function updatePrompt() {
  document.getElementById('count').textContent = `${SECTIONS.filter(s => S.picks[s.id]).length} / ${SECTIONS.length} picked`;
  document.getElementById('prompt').value = promptText();
  document.getElementById('next').innerHTML = `<span class="lab">Then</span> ` + Object.entries(next()).map(([k, [t]]) => `<button class="chipbtn ${S.next === k ? 'on' : ''}" type="button" data-next="${k}" aria-pressed="${S.next === k}">${t}</button>`).join(' ');
}

document.addEventListener('DOMContentLoaded', () => {
  for (const s of SECTIONS) {
    if (!s.opts.every(o => /^[A-Z]$/.test(o.k))) console.error(`design-board: ${s.id}'s option keys must be single capital letters (the pick badge shows them)`);
    DEF[s.id] = (s.opts.find(o => o.rec) || s.opts[0]).k;
  }
  document.title = BOARD.name;
  document.getElementById('eyebrow').textContent = `${BOARD.eyebrow ?? BOARD.name} · round ${BOARD.round}`;
  document.getElementById('headline').textContent = BOARD.headline ?? BOARD.name;
  document.getElementById('footnote').innerHTML = BOARD.footnote ?? '';
  try {
    const saved = JSON.parse(localStorage.getItem(store()) || 'null');
    if (saved) Object.assign(S, { picks: saved.picks || {}, notes: saved.notes || {}, overall: saved.overall || '', next: saved.next });
  } catch (e) {}
  S.next = nextKey(S.next);
  document.addEventListener('click', e => {
    const pick = e.target.closest('[data-pick]');
    if (pick) {
      const [id, k] = pick.dataset.pick.split(':');
      if (S.picks[id] === k) delete S.picks[id]; else S.picks[id] = k;
      save(); renderAll(); return;
    }
    const scen = e.target.closest('[data-scen]');
    if (scen) {
      const [key, v] = scen.dataset.scen.split(':');
      if (scenarios().some(([, k, vals]) => k === key && vals.some(([w]) => w === v))) { S[key] = v; renderAll(); }
      return;
    }
    const nx = e.target.closest('[data-next]');
    if (nx) { S.next = nextKey(nx.dataset.next); save(); updatePrompt(); return; }
    const a = e.target.closest('[data-act]');
    if (!a) return;
    const [act, x, y] = a.dataset.act.split(':');
    if (act === 'noop') return;
    if (onAct(act, x, y, e)) renderAll();
  });
  document.getElementById('copy').addEventListener('click', () => {
    const text = promptText(), msg = document.getElementById('copied');
    const fallback = () => {
      document.querySelector('details.out').open = true;
      const ta = document.getElementById('prompt'); ta.focus(); ta.select();
      msg.textContent = 'Selected below: press Ctrl+C';
    };
    try { navigator.clipboard.writeText(text).then(() => { msg.textContent = 'Copied'; setTimeout(() => { msg.textContent = ''; }, 2500); }, fallback); } catch (err) { fallback(); }
  });
  buildBoard();
  renderAll();
});
