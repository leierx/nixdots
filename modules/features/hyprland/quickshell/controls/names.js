.pragma library

// What a device or network calls itself, made safe for one line: no control characters, no
// direction overrides, invisible marks, Hangul fillers or tag characters that would flip, hide or
// blank the row, and no runaway length.
function clean(name) {
  const text = String(name ?? "")
    .replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]+/g, " ")
    .replace(/[؜​-‏‪-‮⁠-⁩﻿ᅟᅠㅤﾠ]|\udb40[\udc00-\udc7f]/g, "")
    .trim();
  if (text.length <= 300) return text;
  // Never between the halves of a surrogate pair, which would draw a box.
  return text.slice(0, /[\ud800-\udbff]/.test(text[299]) ? 299 : 300);
}
