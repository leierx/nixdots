.pragma library

function words(query) {
  return query.toLowerCase().split(/\s+/).filter(word => word !== "");
}

// -1 is no match.
function scoreLowered(typed, haystack, loose) {
  let total = 0;
  for (const word of typed) {
    const at = haystack.indexOf(word);
    if (at < 0) {
      const letters = loose ? spread(haystack, word) : null;
      if (!letters) {
        // One letter wrong, missing, extra or swapped, as the HIG asks search to forgive; below every match as typed.
        if (!slipped(haystack, word)) {
          return -1;
        }
        total += 300;
        continue;
      }
      // Tighter is better: "ffx" in "firefox" spans all seven letters.
      total += 500 - (letters[letters.length - 1] - letters[0] + 1);
      continue;
    }
    if (at === 0) {
      total += 1000;
    } else if (" -_./:".includes(haystack[at - 1])) {
      total += 900;
    } else {
      total += 700;
    }
  }
  // Shorter text wins a tie: "Firefox" before "Firefox Developer Edition".
  return total - haystack.length / 20;
}

function spread(haystack, word) {
  let best = null;
  for (let start = haystack.indexOf(word[0]); start >= 0; start = haystack.indexOf(word[0], start + 1)) {
    const letters = [start];
    for (const letter of word.slice(1)) {
      const at = haystack.indexOf(letter, letters[letters.length - 1] + 1);
      if (at < 0) {
        return best;
      }
      letters.push(at);
    }
    if (!best || letters[letters.length - 1] - start < best[best.length - 1] - best[0]) {
      best = letters;
    }
  }
  return best;
}

// `fields` are [weight, text, loose?], so a hit in the name beats the same hit in a keyword; no words match everything with 0, keeping the picker's order.
function scoreFields(typed, fields) {
  if (typed.length === 0) {
    return 0;
  }
  let best = -1;
  for (const [weight, text, loose] of fields) {
    // -1 stays negative whatever the weight.
    if (text) {
      best = Math.max(best, scoreLowered(typed, text.toLowerCase(), loose) * weight);
    }
  }
  return best;
}

function escape(text) {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;");
}

function mark(query, text, loose) {
  if (!text) {
    return "";
  }
  const haystack = text.toLowerCase();
  // Lowercasing can change a string's length, and then the marks would land elsewhere.
  if (haystack.length !== text.length) {
    return escape(text);
  }
  const bold = [];
  for (const word of words(query)) {
    const at = haystack.indexOf(word);
    const run = (start, length) => [...Array(length).keys()].map(i => start + i);
    const slip = () => {
      const found = slipped(haystack, word);
      return found ? run(found[0], found[1]) : [];
    };
    const letters = at >= 0 ? run(at, word.length) : (loose ? spread(haystack, word) : null) ?? slip();
    for (const index of letters) {
      bold[index] = true;
    }
  }
  let styled = "";
  for (let start = 0; start < text.length;) {
    let end = start;
    while (end < text.length && !!bold[end] === !!bold[start]) {
      end++;
    }
    const part = escape(text.slice(start, end));
    styled += bold[start] ? `<b>${part}</b>` : part;
    start = end;
  }
  return styled;
}

// A word of four letters or more that some word of the text begins with, but for one slip: where that begins and how long, or null.
function slipped(haystack, word) {
  if (word.length < 4) {
    return null;
  }
  const tokens = /[^\s\-_./:]+/g;
  for (let token = tokens.exec(haystack); token !== null; token = tokens.exec(haystack)) {
    for (let length = word.length - 1; length <= word.length + 1; length++) {
      if (length <= token[0].length && withinOne(token[0].slice(0, length), word)) {
        return [token.index, length];
      }
    }
  }
  return null;
}

// Equal but for one substitution, insertion, deletion or swap of neighbours.
function withinOne(a, b) {
  if (Math.abs(a.length - b.length) > 1) {
    return false;
  }
  let i = 0;
  while (i < a.length && i < b.length && a[i] === b[i]) {
    i++;
  }
  if (i === a.length && i === b.length) {
    return true;
  }
  const swapped = a[i] === b[i + 1] && a[i + 1] === b[i] && a.slice(i + 2) === b.slice(i + 2);
  return swapped || a.slice(i + 1) === b.slice(i + 1) || a.slice(i) === b.slice(i + 1) || a.slice(i + 1) === b.slice(i);
}
