import Quickshell
import Quickshell.Io
import qs.common

// A failure is sent as a notification titled `name` and closes the launcher.
Process {
  id: root

  property string name: command.join(" ")
  // For a load in the background, which nobody is waiting on.
  property bool quiet: false

  signal done(string output)

  function fail(message: string): void {
    if (root.quiet) {
      console.warn(`${root.name}: ${message}`);
      return;
    }
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
