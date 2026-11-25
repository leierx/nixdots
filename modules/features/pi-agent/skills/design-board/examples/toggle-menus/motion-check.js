// check.mjs --eval: drives every mock through each transition and samples it every 75 ms, so each option can be read against its description without watching it.
(async () => {
  const scopes = [...document.querySelectorAll('[data-mock]')].map(r => r.dataset.mock);
  const frame = s => [...document.querySelector(`[data-mock="${s}"]`).querySelectorAll('.slot')].map(sl => Math.round(sl.getBoundingClientRect().height) + ':' + [...sl.querySelectorAll('.menu')].map(m => {
    const cs = getComputedStyle(m), t = new DOMMatrix(cs.transform);
    return m.dataset.key + Number(cs.opacity).toFixed(1) + (t.m41 || t.m42 ? `(${Math.round(t.m41)},${Math.round(t.m42)})` : '');
  }).join(',')).join('|');
  const out = {};
  for (const [from, to] of [['', 'wifi'], ['vpn', 'bluetooth'], ['wifi', 'night'], ['night', '']]) {
    scopes.forEach(s => go(s, from)); await wait(1200);
    const key = `${from || 'closed'} > ${to || 'closed'}`;
    scopes.forEach(s => { (out[s] ??= {})[key] = []; go(s, to); });
    for (let t = 0; t <= 600; t += 75) { scopes.forEach(s => out[s][key].push(`${t} ${frame(s)}`)); await wait(75); }
  }
  return out;
})()
