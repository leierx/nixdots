.pragma library

function words(query) {
  return query.toLowerCase().split(/\s+/).filter(word => word !== "");
}

// Like rofi: every word typed appears somewhere, in any order, or in a loose
// field as its letters in order ("ffx" in Firefox), scored below any whole word.
// -1 is no match; an empty query matches everything with 0, keeping the picker's order.
function score(query, text, loose) {
  const typed = words(query);
  if (typed.length === 0) {
    return 0;
  }
  if (!text) {
    return -1;
  }

  const haystack = text.toLowerCase();
  let total = 0;
  for (const word of typed) {
    const at = haystack.indexOf(word);
    if (at < 0) {
      const letters = loose ? spread(haystack, word) : null;
      if (!letters) {
        return -1;
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

// Where the word's letters fall, in order, over the fewest characters of the text, or null.
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

// `fields` are [weight, text, loose?], so a hit in the name beats the same hit in a keyword.
function scoreFields(query, fields) {
  let best = -1;
  for (const [weight, text, loose] of fields) {
    // -1 stays negative whatever the weight.
    best = Math.max(best, score(query, text, loose) * weight);
  }
  return best;
}

function escape(text) {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;");
}

// The text as StyledText with what score() matched in bold.
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
    const letters = at >= 0 ? [...Array(word.length).keys()].map(i => at + i) : loose ? spread(haystack, word) ?? [] : [];
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
