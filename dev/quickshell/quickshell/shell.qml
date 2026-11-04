//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
  Variants {
    model: Quickshell.screens

    Topbar {}
  }
}