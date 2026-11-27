.pragma library

const limit = 100;
const maxAge = 7 * 24 * 3600 * 1000;
// A clock set back leaves records ahead of it, which would sort first until it caught up; a minute forgives a small step.
const ahead = 60 * 1000;

function valid(record) {
  const strings = ["appName", "appIcon", "desktopEntry", "summary", "body", "image"];
  return record !== null && typeof record === "object" && typeof record.uid === "string" && /^[a-z0-9]+$/.test(record.uid)
    && Number.isFinite(record.time) && typeof record.checked === "boolean" && Number.isInteger(record.urgency)
    && strings.every(name => typeof record[name] === "string") && ["string", "undefined"].includes(typeof record.tag);
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

// The path a file: URL names, "" for any other; its query and fragment are not part of it.
function localPath(url) {
  const file = /^file:(?:\/\/(?:localhost)?)?(\/[^?#]*)/.exec(url);
  if (!file) return "";
  try {
    return decodeURIComponent(file[1]);
  } catch (error) {
    return "";
  }
}

// Encoded, so a # or a % in a name stays part of it.
function fileUrl(path) {
  return `file://${path.split("/").map(encodeURIComponent).join("/")}`;
}
