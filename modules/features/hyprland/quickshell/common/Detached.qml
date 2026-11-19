pragma Singleton

import Quickshell

// In a scope of its own, so the service restarting never takes it along, and without the shell's own scale.
Singleton {
  function run(command: var, workingDirectory: string): void {
    Quickshell.execDetached({
      command: ["systemd-run", "--user", "--scope", "--quiet", ...command],
      workingDirectory: workingDirectory,
      environment: ({ QT_SCALE_FACTOR: null }),
    });
  }
}
