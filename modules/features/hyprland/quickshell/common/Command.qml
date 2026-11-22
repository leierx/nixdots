import Quickshell
import Quickshell.Io

Process {
  id: root

  property string name: command.join(" ")
  // For a load nobody is waiting on: a failure only reaches the log.
  property bool quiet: false
  // The panel open as it started; a failure closes that one, not one opened since.
  property string panel: ""
  property bool exitReported: false

  signal done(string output)
  signal failed(string message)

  function fail(message: string): void {
    if (root.quiet) {
      console.warn(`${root.name}: ${message}`);
    } else {
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Shell", "-i", "dialog-warning", root.name, message]);
      if (Panels.active === root.panel) Panels.close();
    }
    root.failed(message);
  }

  stdout: StdioCollector {
    id: out
  }
  stderr: StdioCollector {
    id: err
  }

  onStarted: root.panel = Panels.active
  // The collectors have their text by the time the process exits.
  onExited: (exitCode, exitStatus) => {
    root.exitReported = true;
    if (exitCode === 0 && exitStatus === 0) root.done(out.text);
    else root.fail(err.text.trim() || (exitStatus !== 0 ? "crashed" : `exited with ${exitCode}`));
  }
  // One that fails to start, not found say, never reports an exit.
  onRunningChanged: {
    if (root.running) return;
    if (!root.exitReported) {
      root.panel = Panels.active;
      root.fail(`${root.command[0]} could not be started`);
    }
    root.exitReported = false;
  }
}
