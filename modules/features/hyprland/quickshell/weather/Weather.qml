pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The timezone's city, from tzdata's coordinates, rather than a lookup of the public address.
Singleton {
  id: root

  property string place: ""
  // Each hour fetched: { time, temperature in °C, symbol: MET's symbol code, icon }.
  property var series: []
  // From the hour under way by the clock, so a forecast that could not be fetched again ages out rather than going stale.
  readonly property var hours: series.filter(hour => hour.time.getTime() > Time.now.getTime() - 60 * 60 * 1000)
  readonly property var now: hours[0] ?? null
  property real attempted: 0
  // The zone whose missing coordinates were said, so they are said once.
  property string unplaced: ""

  // MET's terms ask for a User-Agent naming the app.
  readonly property string userAgent: "nixdots-quickshell github.com/leierx/nixdots"

  // Without the time of day, as the legend names them.
  property var names: ({})

  function icon(symbol: string): string {
    return `file://${Quickshell.shellPath(`weather/icons/${symbol}.svg`)}`;
  }

  // The sky MET's code shows, for the card's gradient: day, night, cloud, rain, snow or storm.
  function sky(symbol: string): string {
    const [kind, time] = symbol.split("_");
    if (kind.includes("thunder")) return "storm";
    if (kind.includes("snow") || kind.includes("sleet")) return "snow";
    if (kind.includes("rain")) return "rain";
    if (kind === "cloudy" || kind === "fog") return "cloud";
    return time === "night" || time === "polartwilight" ? "night" : "day";
  }

  function describe(symbol: string): string {
    return root.names[symbol.split("_")[0]] ?? "";
  }

  function degrees(celsius: real): string {
    return `${Math.round(celsius)}°`;
  }

  function update(): void {
    root.attempted = Date.now();
    refresh.interval = 30 * 60 * 1000;
    refresh.restart();
    locate.running = true;
  }

  // Saved hours as the card reads them.
  function revive(series: var): var {
    return series.map(hour => ({ time: new Date(hour.time), temperature: hour.temperature, symbol: hour.symbol, icon: root.icon(hour.symbol) }));
  }

  // The next look once MET's forecast expires, from ten minutes to two hours on.
  function later(expires: real): void {
    refresh.interval = Math.max(10 * 60 * 1000, Math.min(2 * 60 * 60 * 1000, expires - Date.now() + 60 * 1000));
    refresh.restart();
  }

  function retrySoon(): void {
    refresh.interval = 5 * 60 * 1000;
    refresh.restart();
  }

  FileView {
    path: Quickshell.shellPath("weather/icons/legend.csv")
    onLoaded: {
      const names = {};
      for (const line of text().split("\n").slice(1)) {
        const [id, english] = line.split(",");
        if (english) names[id.trim()] = english.trim();
      }
      root.names = names;
    }
  }

  Timer {
    id: refresh

    repeat: true
    onTriggered: root.update()
  }

  // Qt's timers stand still through a suspend; the clock does not.
  Connections {
    target: Time

    function onNowChanged(): void {
      if (Date.now() - root.attempted > refresh.interval + 60 * 1000) root.update();
    }
  }

  Command {
    id: locate

    name: "Weather: locating"
    quiet: true
    command: ["sh", "-c", 'path=$(readlink -f /etc/localtime) && zone=${path#*/zoneinfo/} && echo "$zone" && awk -F "\t" -v zone="$zone" "\\$3 == zone { print \\$2 }" "${path%%/zoneinfo/*}/zoneinfo/zone.tab"']
    onFailed: root.retrySoon()
    onDone: output => {
      const [zone, coordinates] = output.trim().split("\n");
      // ISO 6709, as zone.tab writes it: +DDMM+DDDMM, seconds after each where known.
      const parts = /^([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?$/.exec(coordinates ?? "");
      if (!parts) {
        // Said once: the zone will not gain coordinates by asking again, and the half-hourly look notices a new one.
        if (root.unplaced !== zone) console.warn(`Weather: no coordinates for ${zone}`);
        root.unplaced = zone;
        return;
      }
      root.unplaced = "";
      const angle = (sign, degrees, minutes, seconds) => (sign === "-" ? -1 : 1) * (Number(degrees) + Number(minutes) / 60 + Number(seconds ?? 0) / 3600);
      // About a kilometre; MET asks for at most four decimals, and fewer share its cache.
      const lat = angle(parts[1], parts[2], parts[3], parts[4]).toFixed(2);
      const lon = angle(parts[5], parts[6], parts[7], parts[8]).toFixed(2);
      root.place = zone.split("/").pop().replace(/_/g, " ");
      const url = `https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${lat}&lon=${lon}`;
      // MET's terms: nothing asked again before its Expires, and asked again only if modified since.
      const same = cache.url === url;
      if (same && cache.expires > Date.now() && cache.series.length > 0) {
        root.series = root.revive(cache.series);
        root.later(cache.expires);
        return;
      }
      forecast.url = url;
      forecast.command = ["curl", "--fail", "--silent", "--show-error", "--max-time", "20", "--dump-header", "-", "--user-agent", root.userAgent, ...(same && cache.modified ? ["--header", `If-Modified-Since: ${cache.modified}`] : []), url];
      forecast.running = true;
    }
  }

  Command {
    id: forecast

    property string url: ""

    name: "Weather: fetching the forecast"
    quiet: true
    onFailed: {
      // The last forecast, however old, until it ages out by the clock.
      if (root.series.length === 0) root.series = root.revive(cache.series);
      root.retrySoon();
    }
    onDone: output => {
      // The headers come first, then a blank line, then the body; a 304 has none.
      const split = output.search(/\r?\n\r?\n/);
      const head = split < 0 ? output : output.slice(0, split);
      const body = split < 0 ? "" : output.slice(split).trim();
      const header = name => new RegExp(`^${name}:\\s*(.+?)\\s*$`, "im").exec(head)?.[1] ?? "";
      const expires = Date.parse(header("expires"));
      try {
        if (!/^HTTP\/\S+ 304/.test(head)) {
          const series = JSON.parse(body).properties.timeseries
            .filter(entry => entry.data.next_1_hours)
            .map(entry => ({ time: entry.time, temperature: entry.data.instant.details.air_temperature, symbol: entry.data.next_1_hours.summary.symbol_code }));
          cache.series = series;
          cache.modified = header("last-modified");
          cache.url = forecast.url;
        }
        cache.expires = Number.isFinite(expires) ? expires : Date.now() + 30 * 60 * 1000;
        root.series = root.revive(cache.series);
        root.later(cache.expires);
      } catch (error) {
        forecast.fail(String(error));
      }
    }
  }

  // The last forecast and what MET said of it, so a restart asks nothing before it expires and a failed fetch keeps it.
  FileView {
    id: file

    path: Quickshell.cachePath("weather.json")
    // There is no file until the first fetch.
    printErrors: false
    onAdapterUpdated: Qt.callLater(writeAdapter)
    // The first look waits for it, once.
    onLoaded: if (root.attempted === 0) root.update()
    onLoadFailed: if (root.attempted === 0) root.update()

    JsonAdapter {
      id: cache

      property string url: ""
      property string modified: ""
      property real expires: 0
      property var series: []
    }
  }
}
