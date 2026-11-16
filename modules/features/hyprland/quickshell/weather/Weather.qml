pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// For where the public address puts the machine, so it follows a laptop around.
Singleton {
  id: root

  property string place: ""
  // From the hour under way: { time, temperature in °C, symbol: MET's symbol code, icon }.
  property var hours: []
  readonly property var now: hours[0] ?? null

  // MET's terms ask for a User-Agent naming the app.
  readonly property string userAgent: "nixdots-quickshell github.com/leierx/nixdots"

  // MET's names for its symbols, from the icons' legend, without the time of day.
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

  function failed(what: string, error): void {
    console.warn(`Weather: ${what} failed: ${error}`);
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

  Process {
    id: locate

    command: ["curl", "--fail", "--silent", "--max-time", "20", "https://ipinfo.io/json"]
    onExited: code => {
      if (code !== 0) root.failed("locating", `curl exited with ${code}`);
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (!text) return;
        try {
          const location = JSON.parse(text);
          // About a kilometre; MET asks for at most four decimals, and fewer share its cache.
          const [lat, lon] = location.loc.split(",").map(n => Number(n).toFixed(2));
          root.place = location.city;
          forecast.command = ["curl", "--fail", "--silent", "--max-time", "20", "--user-agent", root.userAgent, `https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${lat}&lon=${lon}`];
          forecast.running = true;
        } catch (error) {
          root.failed("locating", error);
        }
      }
    }
  }

  Process {
    id: forecast

    onExited: code => {
      if (code !== 0) root.failed("fetching the forecast", `curl exited with ${code}`);
    }

    stdout: StdioCollector {
      onStreamFinished: {
        if (!text) return;
        try {
          const hourAgo = Date.now() - 60 * 60 * 1000;
          root.hours = JSON.parse(text).properties.timeseries
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
          root.failed("fetching the forecast", error);
        }
      }
    }
  }
}
