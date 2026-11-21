pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.nix

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

  // MET's terms ask for a User-Agent naming the app.
  readonly property string userAgent: "nixdots-quickshell github.com/leierx/nixdots"

  // Without the time of day, as the legend names them.
  property var names: ({})

  // Adwaita's weather symbol for MET's code, as GNOME's date menu draws the forecast.
  function icon(symbol: string): string {
    const [kind, time] = symbol.split("_");
    const night = time === "night";
    if (kind === "clearsky") return night ? Symbols.weatherClearNight : Symbols.weatherClear;
    if (kind === "fair" || kind === "partlycloudy") return night ? Symbols.weatherFewCloudsNight : Symbols.weatherFewClouds;
    if (kind === "fog") return Symbols.weatherFog;
    if (kind.includes("thunder")) return Symbols.weatherStorm;
    if (kind.includes("snow") || kind.includes("sleet")) return Symbols.weatherSnow;
    if (kind.includes("showers")) return Symbols.weatherShowersScattered;
    if (kind.includes("rain")) return Symbols.weatherShowers;
    return Symbols.weatherOvercast;
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

  function retrySoon(): void {
    refresh.interval = 5 * 60 * 1000;
    refresh.restart();
  }

  Component.onCompleted: update()

  FileView {
    path: Quickshell.shellPath("weather/met/legend.csv")
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
        locate.fail(`no coordinates for ${zone}`);
        return;
      }
      const angle = (sign, degrees, minutes, seconds) => (sign === "-" ? -1 : 1) * (Number(degrees) + Number(minutes) / 60 + Number(seconds ?? 0) / 3600);
      // About a kilometre; MET asks for at most four decimals, and fewer share its cache.
      const lat = angle(parts[1], parts[2], parts[3], parts[4]).toFixed(2);
      const lon = angle(parts[5], parts[6], parts[7], parts[8]).toFixed(2);
      root.place = zone.split("/").pop().replace(/_/g, " ");
      forecast.command = ["curl", "--fail", "--silent", "--max-time", "20", "--user-agent", root.userAgent, `https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${lat}&lon=${lon}`];
      forecast.running = true;
    }
  }

  Command {
    id: forecast

    name: "Weather: fetching the forecast"
    quiet: true
    onFailed: root.retrySoon()
    onDone: output => {
      try {
        root.series = JSON.parse(output).properties.timeseries
          .filter(entry => entry.data.next_1_hours)
          .map(entry => {
            const symbol = entry.data.next_1_hours.summary.symbol_code;
            return {
              time: new Date(entry.time),
              temperature: entry.data.instant.details.air_temperature,
              symbol,
              icon: root.icon(symbol),
            };
          });
      } catch (error) {
        forecast.fail(String(error));
      }
    }
  }
}
