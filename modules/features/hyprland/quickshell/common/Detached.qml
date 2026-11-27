pragma Singleton

import Quickshell

// In a scope of its own, so the service restarting never takes it along, and without the shell's own scale.
Singleton {
  function run(command: var, workingDirectory: string): void {
    Quickshell.execDetached({
      // A program that is not there says so, as a Command does: detached, its failure would reach no one.
      command: ["sh", "-c", 'if command -v "$1" > /dev/null; then exec systemd-run --user --scope --quiet "$@"; fi; exec notify-send -u critical -a Shell -i dialog-warning -- "$1" "$1 could not be started"', "sh", ...command],
      workingDirectory: workingDirectory,
      environment: ({ QT_SCALE_FACTOR: null }),
    });
  }
}
