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
  // Milliseconds it may take before it is stopped and fails; 0 for as long as it takes.
  property alias timeout: limit.interval
  property bool timedOut: false

  signal done(string output)
  signal failed(string message)

  function fail(message: string): void {
    if (root.quiet) {
      console.warn(`${root.name}: ${message}`);
    } else {
      // Its end, as text: the server reads markup, and one argument past 128 KiB never starts notify-send.
      const end = message.length > 1000 ? `…${message.slice(-1000)}` : message;
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Shell", "-i", "dialog-warning", "--", root.name, end.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")]);
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

  property Deadline deadline: Deadline {
    id: limit

    process: root
    onExpired: root.timedOut = true
  }

  onStarted: {
    root.panel = Panels.active;
    root.timedOut = false;
  }
  // The collectors have their text by the time the process exits.
  onExited: (exitCode, exitStatus) => {
    root.exitReported = true;
    if (root.timedOut) root.fail(`no answer in ${Theme.unit(Math.round(root.timeout / 1000), "s")}`);
    else if (exitCode === 0 && exitStatus === 0) root.done(out.text);
    else root.fail(err.text.trim() || (exitStatus !== 0 ? "crashed" : `exited with ${exitCode}`));
  }
  // One that fails to start, not found say, never reports an exit. A run started from the last one's exit handler reads running as that one ends.
  onRunningChanged: {
    if (root.running) {
      root.exitReported = false;
      return;
    }
    if (!root.exitReported) {
      root.panel = Panels.active;
      root.fail(`${root.command[0]} could not be started`);
    }
    root.exitReported = false;
  }
}
