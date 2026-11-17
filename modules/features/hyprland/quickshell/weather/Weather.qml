pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The timezone's city, from tzdata's coordinates, rather than a lookup of the public address.
Singleton {
  id: root

  property string place: ""
  // From the hour under way: { time, temperature in °C, symbol: MET's symbol code, icon }.
  property var hours: []
  readonly property var now: hours[0] ?? null

  // MET's terms ask for a User-Agent naming the app.
  readonly property string userAgent: "nixdots-quickshell github.com/leierx/nixdots"

  // Without the time of day, as the legend names them.
  property var names: ({})

  function icon(symbol: string): string {
    return `file://${Quickshell.shellPath(`weather/icons/${symbol}.svg`)}`;
  }

  function describe(symbol: string): string {
    return root.names[symbol.split("_")[0]] ?? "";
  }

  function degrees(celsius: real): string {
    return `${Math.round(celsius)}°`;
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

    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      interval = 30 * 60 * 1000;
      locate.running = true;
    }
  }

  // The zone /etc/localtime points at, and its line in the zone.tab beside it.
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
        const hourAgo = Date.now() - 60 * 60 * 1000;
        root.hours = JSON.parse(output).properties.timeseries
          .filter(entry => Date.parse(entry.time) > hourAgo && entry.data.next_1_hours)
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
