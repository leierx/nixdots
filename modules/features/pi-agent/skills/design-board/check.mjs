#!/usr/bin/env node
// Loads a board in headless Chromium over the DevTools protocol, in real time (WAAPI never advances under
// --virtual-time-budget), and prints JSON: errors, a summary of the questions, an --eval's value, the shots.
// Exits 1 on any page error. Node 22+ only, no packages.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const usage = 'usage: check.mjs BOARD_DIR|FILE [--shots DIR] [--eval EXPR|FILE] [--width PX] [--browser PATH] [--timeout S]';
const opt = { width: 1500, timeout: 120 };
let target;
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--shots') opt.shots = argv[++i];
  else if (a === '--eval') opt.eval = argv[++i];
  else if (a === '--width') opt.width = Number(argv[++i]);
  else if (a === '--browser') opt.browser = argv[++i];
  else if (a === '--timeout') opt.timeout = Number(argv[++i]);
  else if (a.startsWith('--')) { console.error(usage); process.exit(2); }
  else target = a;
}
if (!target || typeof WebSocket === 'undefined') { console.error(typeof WebSocket === 'undefined' ? 'check.mjs needs Node 22 or later' : usage); process.exit(2); }
let file = path.resolve(target);
if (fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
const url = pathToFileURL(file).href;

function browser() {
  const chosen = opt.browser || process.env.DESIGN_BOARD_BROWSER;
  if (chosen) return [chosen];
  for (const name of ['chromium', 'chromium-browser', 'google-chrome-stable', 'google-chrome', 'brave', 'microsoft-edge']) {
    try { const found = execFileSync('sh', ['-c', `command -v ${name}`]).toString().trim(); if (found) return [found]; } catch {}
  }
  const mac = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  if (fs.existsSync(mac)) return [mac];
  if (process.platform === 'linux') return ['nix', 'shell', 'nixpkgs#chromium', '-c', 'chromium'];
  throw new Error('no Chromium-family browser found: pass --browser PATH');
}

const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'design-board-check-'));
const [cmd, ...pre] = browser();
const env = { ...process.env };
// A dev shell's libraries break nixpkgs' Chromium.
delete env.LD_LIBRARY_PATH;
const child = spawn(cmd, [...pre, '--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--hide-scrollbars', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'], { env, stdio: ['ignore', 'ignore', 'pipe'] });
const timer = setTimeout(() => finish({ error: `timed out after ${opt.timeout} s` }, 1), opt.timeout * 1000);

let ws, id = 0;
const pending = new Map(), handlers = [];
function send(method, params = {}, sessionId) {
  return new Promise((resolve, reject) => {
    const i = ++id;
    pending.set(i, m => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
    ws.send(JSON.stringify({ id: i, method, params, ...(sessionId ? { sessionId } : {}) }));
  });
}
const event = (method, sessionId) => new Promise(resolve => handlers.push({ method, sessionId, resolve, once: true }));

let done = false;
async function finish(result, code) {
  if (done) return;
  done = true;
  clearTimeout(timer);
  console.log(JSON.stringify(result, null, 1));
  try { await Promise.race([send('Browser.close'), new Promise(r => setTimeout(r, 2000))]); } catch {}
  setTimeout(() => { try { child.kill('SIGKILL'); } catch {} }, 1500).unref();
  const rm = () => fs.rmSync(profile, { recursive: true, force: true });
  if (child.exitCode !== null || child.signalCode !== null) rm(); else child.once('exit', rm);
  setTimeout(() => process.exit(code), 1600);
}

const wsUrl = await new Promise((resolve, reject) => {
  let err = '';
  child.stderr.on('data', d => {
    err += d;
    const m = err.match(/DevTools listening on (ws:\/\/\S+)/);
    if (m) resolve(m[1]);
  });
  child.once('exit', c => reject(new Error(`browser exited (${c}): ${err.slice(-500)}`)));
  child.once('error', e => reject(new Error(`browser failed to start: ${e.message}`)));
}).catch(e => finish({ error: String(e.message) }, 1));
if (done) await new Promise(() => {});

ws = new WebSocket(wsUrl);
await new Promise(r => (ws.onopen = r));
const errors = [], log = [];
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); return; }
  if (m.method === 'Runtime.exceptionThrown') errors.push(m.params.exceptionDetails.exception?.description ?? m.params.exceptionDetails.text);
  if (m.method === 'Runtime.consoleAPICalled' && (m.params.type === 'error' || m.params.type === 'assert')) errors.push(m.params.args.map(a => a.value ?? a.description).join(' '));
  if (m.method === 'Log.entryAdded' && m.params.entry.level === 'error') log.push(m.params.entry.text + (m.params.entry.url ? ` (${m.params.entry.url})` : ''));
  for (const h of [...handlers]) if (h.method === m.method && (!h.sessionId || h.sessionId === m.sessionId)) { handlers.splice(handlers.indexOf(h), 1); h.resolve(m.params); }
};

try {
  const { targetInfos } = await send('Target.getTargets');
  const page = targetInfos.find(t => t.type === 'page');
  const { sessionId: s } = await send('Target.attachToTarget', { targetId: page.targetId, flatten: true });
  const evaluate = async expression => {
    const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }, s);
    if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? r.exceptionDetails.text);
    return r.result.value;
  };
  await Promise.all([send('Runtime.enable', {}, s), send('Log.enable', {}, s), send('Page.enable', {}, s)]);
  await send('Emulation.setDeviceMetricsOverride', { width: opt.width, height: 1000, deviceScaleFactor: 1, mobile: false }, s);
  const loaded = event('Page.loadEventFired', s);
  await send('Page.navigate', { url }, s);
  await loaded;
  await evaluate('document.fonts.ready.then(() => new Promise(r => setTimeout(r, 300)))');
  const summary = await evaluate(`(() => {
    const secs = [...document.querySelectorAll('section.sec[id^="s-"]')].filter(x => x.id !== 's-together');
    return {
      href: location.href,
      board: typeof BOARD !== 'undefined',
      title: document.title,
      questions: secs.map(x => ({ id: x.id.slice(2), options: x.querySelectorAll('.opt').length, empty: [...x.querySelectorAll('.stage')].filter(st => !st.children.length).length })),
      together: !!document.querySelector('#together .stage'),
      // A mock wider than its option card scrolls sideways.
      overflowing: [...document.querySelectorAll('.stage')].filter(st => st.scrollWidth > st.clientWidth + 1).map(st => st.closest('section')?.id ?? '?'),
      height: document.documentElement.scrollHeight
    };
  })()`);
  if (!summary.board) errors.push(`no BOARD on the page (${summary.href})`);
  else if (!summary.questions.length) errors.push(`no questions on the page (${summary.href})`);
  let value;
  if (opt.eval) value = await evaluate(fs.existsSync(opt.eval) ? fs.readFileSync(opt.eval, 'utf8') : opt.eval);
  const shots = [];
  if (opt.shots) {
    fs.mkdirSync(opt.shots, { recursive: true });
    // Fixed and sticky chrome would land in the middle of a section's shot.
    await evaluate(`document.querySelectorAll('.dock, .scen').forEach(el => { el.style.visibility = 'hidden'; el.style.position = 'static'; })`);
    const rects = await evaluate(`[...document.querySelectorAll('section.sec[id^="s-"]')].map(x => { const r = x.getBoundingClientRect(); return { id: x.id.slice(2), x: r.left + scrollX, y: r.top + scrollY, width: r.width, height: Math.min(r.height, 4000) }; })`);
    for (const r of rects) {
      const { data } = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true, clip: { x: r.x, y: r.y, width: r.width, height: r.height, scale: 1 } }, s);
      const out = path.join(opt.shots, `${r.id}.png`);
      fs.writeFileSync(out, Buffer.from(data, 'base64'));
      shots.push(out);
    }
  }
  finish({ url, errors, log, summary, ...(opt.eval ? { eval: value } : {}), ...(opt.shots ? { shots } : {}) }, errors.length ? 1 : 0);
} catch (e) {
  finish({ error: String(e.message ?? e), errors, log }, 1);
}
