pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The weather where this machine is: MET Norway's forecast, yr.no's, for the
// place its public address puts it (ipinfo.io), so it follows a laptop around.
// Looked up every half hour; the last forecast stays while offline. Read
// `hours` for a forecast, or `now` for the hour under way.
Singleton {
  id: root

  // Where the forecast is for, as "Oslo".
  property string place: ""
  // From the hour under way: { time, temperature in °C, symbol: MET's symbol code, icon }.
  property var hours: []
  readonly property var now: hours[0] ?? null

  // MET's terms ask for a User-Agent naming the app.
  readonly property string userAgent: "nixdots-quickshell github.com/leierx/nixdots"

  // MET's symbol code ("rainshowers_day") as a freedesktop weather icon.
  function icon(symbol: string): string {
    const [kind, time] = symbol.split("_");
    const night = time === "night";
    const timed = name => `${name}-${night ? "night" : "day"}`;
    if (kind === "clearsky") return night ? "weather-clear-night" : "weather-clear";
    if (kind === "fair" || kind === "partlycloudy") return night ? "weather-few-clouds-night" : "weather-few-clouds";
    if (kind === "cloudy") return "weather-overcast";
    if (kind === "fog") return "weather-fog";
    if (kind.includes("thunder")) return timed("weather-storm");
    if (kind.includes("sleet")) return "weather-snow-rain";
    if (kind.includes("snowshowers")) return timed("weather-snow-scattered");
    if (kind.includes("snow")) return "weather-snow";
    if (kind.includes("rainshowers")) return timed("weather-showers-scattered");
    if (kind.includes("rain")) return "weather-showers";
    return "weather-none-available";
  }

  function failed(what: string, error): void {
    console.warn(`Weather: ${what} failed: ${error}`);
    refresh.interval = 5 * 60 * 1000;
    refresh.restart();
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
            .filter(entry => entry.data.next_1_hours && Date.parse(entry.time) > hourAgo)
            .map(entry => {
              const symbol = entry.data.next_1_hours.summary.symbol_code;
              return { time: new Date(entry.time), temperature: entry.data.instant.details.air_temperature, symbol, icon: root.icon(symbol) };
            });
        } catch (error) {
          root.failed("fetching the forecast", error);
        }
      }
    }
  }
}
