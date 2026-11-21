.pragma library

const limit = 100;
const maxAge = 7 * 24 * 3600 * 1000;
// A clock set back leaves records ahead of it, which would sort first until it caught up; a minute forgives a small step.
const ahead = 60 * 1000;

function valid(record) {
  const strings = ["appName", "appIcon", "desktopEntry", "summary", "body", "image"];
  return record !== null && typeof record === "object" && typeof record.uid === "string" && /^[a-z0-9]+$/.test(record.uid)
    && Number.isFinite(record.time) && typeof record.checked === "boolean" && Number.isInteger(record.urgency)
    && strings.every(name => typeof record[name] === "string");
}

// The newest within the limits, newest first, as saved.
function current(records, now) {
  return records.filter(record => now - record.time < maxAge && record.time - now < ahead).sort((a, b) => b.time - a.time).slice(0, limit);
}

// What a saved file still holds that can be shown, and why the rest could not be read; a damaged file is no error.
function parse(text, now) {
  let saved;
  try {
    saved = JSON.parse(text);
  } catch (error) {
    return { records: [], problem: `unreadable (${error})` };
  }
  if (!Array.isArray(saved?.notifications)) return { records: [], problem: "holds no notifications" };
  return { records: current(saved.notifications.filter(valid), now), problem: "" };
}

// Records as current() keeps them.
function serialise(records) {
  return JSON.stringify({ version: 1, notifications: records });
}
