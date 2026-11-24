.pragma library

// Rows rebuilt from bindings, each unchanged one the very object it was before. A ScriptModel with
// objectProp goes on replacing rows in place while old and new objects differ, past rows whose keys
// do not match (TODO.md): with every row new, an insertion became a rename of each row after it and
// an append, and a row's own state and animations went to another.
function keep(memo, rows, key) {
  const old = new Map((memo.rows ?? []).map(row => [row[key], row]));
  const result = rows.map(row => {
    const was = old.get(row[key]);
    return was !== undefined && same(was, row) ? was : row;
  });
  memo.rows = result;
  return result;
}

// Plain objects and arrays by what they hold; anything else (a QObject, a function) by identity.
function same(a, b) {
  if (a === b) return true;
  if (!plain(a) || !plain(b) || Array.isArray(a) !== Array.isArray(b)) return false;
  const keys = Object.keys(a);
  return keys.length === Object.keys(b).length && keys.every(name => Object.prototype.hasOwnProperty.call(b, name) && same(a[name], b[name]));
}

function plain(value) {
  if (value === null || typeof value !== "object") return false;
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === Array.prototype || proto === null;
}
