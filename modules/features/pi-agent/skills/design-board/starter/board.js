/* A board's own part. The engine (engine.js, loaded before this) provides S, W, P, ms, the motion kit and the page. */
const BOARD = {
  name: 'BOARD NAME',
  slug: 'SLUG',
  round: 1,
  eyebrow: 'SUBJECT',
  headline: 'BOARD HEADLINE',
  footnote: 'What stands in for what (fonts, data), so nobody mistakes a mock for the real thing.'
};
const DECIDED = ['What the user already settled, one line each.'];

/* Scenario chips switch state the mocks read; add SPEED for a motion question. */
Object.assign(S, { mode: 'a', on: {} });
const SCENARIOS = [
  ['Mode', 'mode', [['a', 'Normal'], ['b', 'Stress']]]
];

/* Renderers read picks through P(id); interactive bits carry data-act="verb:arg:arg" (no ':' inside an arg). */
function demo(scope) {
  const r = { A: '17px', B: '9px', C: '0' }[P('shape')];
  return `<div class="demo">${['wifi', 'bluetooth', 'nightlight'].map(k => `<button class="${S.on[scope + k] ? 'on' : ''}" style="border-radius:${r}" data-act="toggle:${scope + k}">${ms(k, 20)}${k}</button>`).join('')}</div>`;
}

/* One option per question gets rec: true. Keys are single capital letters (the pick badge shows them). */
const SECTIONS = [
  { group: 'Example', id: 'shape', title: 'Button shape',
    q: 'One sentence on what is being decided and how to try the mocks.',
    opts: [
      { k: 'A', name: 'Pill', desc: 'Fully rounded.', rec: true },
      { k: 'B', name: 'Rounded', desc: 'A 9 px radius.' },
      { k: 'C', name: 'Square', desc: 'No radius.' }
    ], render: k => W({ shape: k }, () => demo('sh' + k)) }
];
function renderTogether() { return `<div class="opt"><div class="stage" style="min-height:200px">${demo('asm')}</div></div>`; }
function onAct(act, x) {
  if (act === 'toggle') { S.on[x] = !S.on[x]; return true; }   // true re-renders every mock
  return false;
}
