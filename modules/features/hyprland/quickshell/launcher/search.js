.pragma library

// Search shared by every picker, matching the way rofi does by default: every
// word typed has to appear somewhere in the text, in any order, so "term wez"
// finds WezTerm. In a loose field (an app's name) a word may also match as its
// letters in order with gaps between, so "ffx" finds Firefox, scoring below
// any word that appears whole.
//
// score() is -1 when the text does not match, and otherwise a number where
// bigger is better. An empty query matches everything with 0, which leaves the
// picker's own order alone.

function score(query, text, loose) {
  const words = query.toLowerCase().split(/\s+/).filter(word => word !== "");
  if (words.length === 0) {
    return 0;
  }
  if (!text) {
    return -1;
  }

  const haystack = text.toLowerCase();
  let total = 0;
  for (const word of words) {
    const at = haystack.indexOf(word);
    if (at < 0) {
      const span = loose ? spread(haystack, word) : -1;
      if (span < 0) {
        return -1;
      }
      // Tighter is better: "ffx" in "firefox" spans all seven letters.
      total += 500 - span;
      continue;
    }
    // The start of the text beats the start of a later word, which beats
    // the middle of one.
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

// The fewest characters of the text that hold the word's letters in order, or
// -1 if they are not all there.
function spread(haystack, word) {
  let best = -1;
  for (let start = haystack.indexOf(word[0]); start >= 0; start = haystack.indexOf(word[0], start + 1)) {
    let at = start;
    for (const letter of word.slice(1)) {
      at = haystack.indexOf(letter, at + 1);
      if (at < 0) {
        return best;
      }
    }
    if (best < 0 || at - start + 1 < best) {
      best = at - start + 1;
    }
  }
  return best;
}

// The best score over several fields, each scaled by its weight, so that a
// hit in the name beats the same hit in a keyword. `fields` is a list of
// [weight, text, loose] triples, `loose` optional.
function scoreFields(query, fields) {
  let best = -1;
  for (const [weight, text, loose] of fields) {
    // -1 stays negative whatever the weight.
    best = Math.max(best, score(query, text, loose) * weight);
  }
  return best;
}
