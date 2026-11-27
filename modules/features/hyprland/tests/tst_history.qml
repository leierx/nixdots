import QtQuick
import QtTest
import "../quickshell/notifications/history.js" as Saved

TestCase {
  name: "NotificationHistory"

  readonly property real now: 1800000000000

  function record(uid, ago) {
    return { uid, time: now - ago, checked: false, appName: "Chat", appIcon: "", desktopEntry: "", summary: uid, body: "", image: "", urgency: 1 };
  }

  function test_round_trip() {
    const records = [record("a", 1000), Object.assign(record("b", 2000), { tag: "volume" })];
    compare(Saved.parse(Saved.serialise(records), now), { records, problem: "" });
  }

  function test_damaged() {
    for (const text of ["", "{", "null", "[]", "{\"notifications\": 3}", "\u0000\u0001"]) {
      const saved = Saved.parse(text, now);
      compare(saved.records, [], text);
      verify(saved.problem !== "", text);
    }
  }

  function test_bad_records_dropped() {
    const good = record("a", 1000);
    const text = JSON.stringify({ notifications: [good, null, 3, "x", Object.assign({}, good, { uid: "../x" }), Object.assign({}, good, { time: "1" }), Object.assign({}, good, { summary: 4 }), Object.assign({}, good, { tag: 5 })] });
    compare(Saved.parse(text, now).records, [good]);
  }

  function test_limits() {
    const many = Array.from({ length: 150 }, (_, i) => record(`n${i}`, i * 1000));
    const kept = Saved.parse(JSON.stringify({ notifications: [...many, record("old", 8 * 24 * 3600 * 1000)] }), now).records;
    compare(kept.length, 100);
    compare(kept[0].uid, "n0");
    verify(!kept.some(r => r.uid === "old"));
  }

  function test_future_dropped() {
    const text = JSON.stringify({ notifications: [record("soon", -30 * 1000), record("ahead", -3600 * 1000)] });
    compare(Saved.parse(text, now).records.map(r => r.uid), ["soon"]);
  }

  function test_file_urls_data() {
    return [
      { tag: "plain", path: "/tmp/a.png", url: "file:///tmp/a.png" },
      { tag: "a space, a hash, a percent and a question mark", path: "/tmp/Shot #2 100%?.png", url: "file:///tmp/Shot%20%232%20100%25%3F.png" },
    ];
  }

  function test_file_urls(data) {
    compare(Saved.fileUrl(data.path), data.url);
    compare(Saved.localPath(data.url), data.path);
  }

  function test_local_path_data() {
    return [
      { tag: "localhost", url: "file://localhost/tmp/a", path: "/tmp/a" },
      { tag: "one slash", url: "file:/tmp/a", path: "/tmp/a" },
      { tag: "fragment and query", url: "file:///tmp/a%20b#c?d", path: "/tmp/a b" },
      { tag: "a broken escape", url: "file:///tmp/%E0%A4%A", path: "" },
      { tag: "relative", url: "file:a", path: "" },
      { tag: "a bare path", url: "/tmp/a", path: "" },
      { tag: "an icon", url: "image://icon//tmp/a", path: "" },
    ];
  }

  function test_local_path(data) {
    compare(Saved.localPath(data.url), data.path);
  }
}
