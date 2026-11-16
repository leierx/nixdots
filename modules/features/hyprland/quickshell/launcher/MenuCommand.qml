import Quickshell
import Quickshell.Io
import qs.common

// A failure is sent as a notification titled `name` and closes the launcher.
Process {
  id: root

  property string name: command.join(" ")

  signal done(string output)

  function fail(message: string): void {
    Quickshell.execDetached(["notify-send", "-u", "critical", root.name, message]);
    Panels.close();
  }

  stdout: StdioCollector {
    id: out
  }
  stderr: StdioCollector {
    id: err
  }

  // The collectors have their text by the time the process exits.
  onExited: exitCode => {
    if (exitCode === 0) root.done(out.text);
    else root.fail(err.text);
  }
}
