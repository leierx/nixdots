.pragma library

// What a device or network calls itself, made safe for one line: no control characters, no
// direction overrides or invisible marks that would flip or hide the row, and no runaway length.
function clean(name) {
  const text = String(name ?? "").replace(/[\u0000-\u001f\u007f-\u009f]+/g, " ").replace(/[؜​-‏‪-‮⁠-⁩﻿]/g, "").trim();
  return text.length > 300 ? text.slice(0, 300) : text;
}
