import Quickshell
import Quickshell.Io
import qs.nix
import qs.services

// Runs `command` once, as the menu holding it opens, and hands its output to
// `done`. A failure is sent as a notification and closes the menu.
//
//   MenuCommand {
//     command: [Bin.cliphist, "list"]
//     onDone: output => root.rows = parse(output)
//   }
Process {
  id: root

  signal done(string output)

  running: true
  stdout: StdioCollector {
    id: out
  }
  stderr: StdioCollector {
    id: err
  }

  // The collectors have their text by the time the process exits.
  onExited: exitCode => {
    if (exitCode === 0) {
      root.done(out.text);
      return;
    }
    const name = [root.command[0].split("/").pop(), ...root.command.slice(1)].join(" ");
    Quickshell.execDetached([Bin.notifySend, "-u", "critical", name, err.text]);
    MenuState.close();
  }
}
