import QtQuick
import Quickshell

// qs-test puts one in every window of its copy of the shell, since nothing lists a shell's windows.
Item {
  id: marker

  // The file the window is declared in, which names it.
  required property string file
  readonly property var window: QsWindow.window

  Component.onCompleted: ProbeWindows.markers = [...ProbeWindows.markers, marker]
  Component.onDestruction: ProbeWindows.markers = ProbeWindows.markers.filter(other => other !== marker)
}
