pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// For where the public address puts the machine, so it follows a laptop around.
Singleton {
  id: root

  property string place: ""
  // From the hour under way: { time, temperature in °C, wind in m/s, rain in mm, symbol: MET's symbol code, icon }.
  property var hours: []
  readonly property var now: hours[0] ?? null
  // Yr's quarters of a day from the one under way: { start, quarter (0 for the night), low, high in °C, symbol, icon }.
  property var periods: []

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

  // Empty when MET rounds it to nothing.
  function millimetres(amount: real): string {
    return amount >= 0.05 ? `${amount.toFixed(1)} mm` : "";
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
          const series = JSON.parse(text).properties.timeseries
            .filter(entry => Date.parse(entry.time) > hourAgo)
            .map(entry => ({ time: new Date(entry.time), data: entry.data }));

          root.hours = series
            .filter(entry => entry.data.next_1_hours)
            .map(entry => {
              const symbol = entry.data.next_1_hours.summary.symbol_code;
              return {
                time: entry.time,
                temperature: entry.data.instant.details.air_temperature,
                wind: entry.data.instant.details.wind_speed,
                rain: entry.data.next_1_hours.details.precipitation_amount ?? 0,
                symbol,
                icon: root.icon(symbol),
              };
            });

          // Yr's quarters of a day, each as MET's six-hour forecast from its first entry: hourly for
          // two days and six-hourly after, so a quarter starts where the forecast has an entry.
          const periods = [];
          for (const entry of series) {
            const next = entry.data.next_6_hours;
            const quarter = Math.floor(entry.time.getHours() / 6);
            const start = new Date(entry.time.getFullYear(), entry.time.getMonth(), entry.time.getDate(), quarter * 6);
            if (!next || periods.some(period => period.start.getTime() === start.getTime())) continue;
            const end = new Date(start.getTime() + 6 * 60 * 60 * 1000);
            const values = series
              .filter(other => other.time >= start && other.time < end)
              .map(other => other.data.instant.details.air_temperature);
            periods.push({
              start,
              quarter,
              low: Math.min(...values),
              high: Math.max(...values),
              symbol: next.summary.symbol_code,
              icon: root.icon(next.summary.symbol_code),
            });
          }
          root.periods = periods;
        } catch (error) {
          root.failed("fetching the forecast", error);
        }
      }
    }
  }
}
