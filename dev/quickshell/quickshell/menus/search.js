.pragma library

// Search shared by every menu, matching the way rofi does by default: every
// word typed has to appear somewhere in the text, in any order, so "term wez"
// finds WezTerm.
//
// score() is -1 when the text does not match, and otherwise a number where
// bigger is better. An empty query matches everything with 0, which leaves the
// menu's own order alone.

function score(query, text) {
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
      return -1;
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

// The best score over several fields, each scaled by its weight, so that a
// hit in the name beats the same hit in a keyword. `fields` is a list of
// [weight, text] pairs.
function scoreFields(query, fields) {
  let best = -1;
  for (const [weight, text] of fields) {
    // -1 stays negative whatever the weight.
    best = Math.max(best, score(query, text) * weight);
  }
  return best;
}
