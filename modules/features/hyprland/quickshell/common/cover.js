.pragma library

function linear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function encoded(c) {
  return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

// Björn Ottosson's OKLab.
function lab(color) {
  const r = linear(color.r), g = linear(color.g), b = linear(color.b);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s];
}

function rgb(L, a, b) {
  const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
  const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
  const s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3);
  return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s].map(encoded);
}

function hex(channels) {
  return "#" + channels.map(c => Math.round(Math.min(1, Math.max(0, c)) * 255).toString(16).padStart(2, "0")).join("");
}

// The hue at a lightness, its chroma eased down until it fits sRGB.
function lch(L, C, h) {
  for (let i = 0; i < 60; i++) {
    const channels = rgb(L, C * Math.cos(h), C * Math.sin(h));
    if (channels.every(c => c >= -0.001 && c <= 1.001)) return hex(channels);
    C *= 0.93;
  }
  return hex(rgb(L, 0, 0));
}

// ColorQuantizer's colours each stand for an equal share of the cover: the one with the most colour and the most like it wins, near black and near white only when nothing else is there.
function cover(colors) {
  const all = Array.from(colors ?? [], color => {
    const [L, a, b] = lab(color);
    return { L, a, b, C: Math.hypot(a, b) };
  });
  if (all.length === 0) return null;
  let best = null, score = -1;
  for (const one of all) {
    const alike = all.filter(other => Math.hypot(other.L - one.L, other.a - one.a, other.b - one.b) < 0.1).length;
    const weight = one.L < 0.2 || one.L > 0.97 ? 0.02 : 0.08 + Math.min(1, one.C / 0.1);
    if (weight * alike > score) {
      best = one;
      score = weight * alike;
    }
  }
  const h = Math.atan2(best.b, best.a);
  // At OKLab 0.40 white text reads past 7:1 whatever the hue.
  const card = lch(0.4, Math.min(best.C, 0.12), h);
  if (best.C < 0.03) return { card, accent: "", accentHover: "", accentPressed: "" };
  const C = Math.min(best.C + 0.02, 0.14);
  return { card, accent: lch(0.84, C, h), accentHover: lch(0.8, C, h), accentPressed: lch(0.76, C, h) };
}
