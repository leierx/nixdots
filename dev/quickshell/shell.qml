//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
  // one topbar per monitor
  Variants {
    model: Quickshell.screens

    Topbar {}
  }
}