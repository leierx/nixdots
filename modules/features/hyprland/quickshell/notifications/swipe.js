.pragma library

// How far a card moves while the card `swiped` places from it is dragged by
// `distance`: the dragged one follows the pointer and its next two neighbours
// lean along, letting go once the swipe is far enough to dismiss.
function lean(index, swiped, distance, threshold) {
  if (swiped < 0) return 0;
  const away = Math.abs(swiped - index);
  if (away === 0) return distance;
  if (Math.abs(distance) > threshold) return 0;
  return distance * ([0, 0.3, 0.1][away] ?? 0);
}
