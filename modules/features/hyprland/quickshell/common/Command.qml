import Quickshell
import Quickshell.Io

Process {
  id: root

  property string name: command.join(" ")
  // For a load nobody is waiting on: a failure only reaches the log.
  property bool quiet: false

  signal done(string output)
  signal failed(string message)

  function fail(message: string): void {
    if (root.quiet) {
      console.warn(`${root.name}: ${message}`);
    } else {
      Quickshell.execDetached(["notify-send", "-u", "critical", root.name, message]);
      Panels.close();
    }
    root.failed(message);
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
    else root.fail(err.text.trim() || `exited with ${exitCode}`);
  }
}
