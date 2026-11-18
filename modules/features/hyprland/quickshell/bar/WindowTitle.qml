import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.common

// The window in front on this monitor: its program's icon and name, then its title.
Row {
  id: root

  required property HyprlandMonitor monitor
  property real maxWidth: 400
  readonly property bool focused: monitor !== null && Hyprland.focusedMonitor === monitor
  // Hyprland's, which an empty workspace clears; another monitor shows the first window on its own.
  readonly property HyprlandToplevel window: {
    const active = Hyprland.activeToplevel;
    if (focused && active?.workspace?.monitor === monitor) return active;
    if (focused) return null;
    return monitor?.activeWorkspace?.toplevels.values[0] ?? null;
  }
  // qmllint disable missing-property redundant-optional-chaining
  // Null until Hyprland reports the window's address; qmllint takes it for never null and without an app id.
  readonly property string appId: window?.wayland?.appId ?? ""
  // qmllint enable missing-property redundant-optional-chaining
  readonly property DesktopEntry entry: appId ? DesktopEntries.heuristicLookup(appId) : null
  readonly property string name: entry?.name ?? appId
  readonly property string title: window?.title ?? ""

  visible: window !== null
  spacing: 8
  opacity: focused ? 1 : 0.6

  IconImage {
    anchors.verticalCenter: parent.verticalCenter
    implicitSize: 16
    source: Quickshell.iconPath(root.entry?.icon || root.appId, "application-x-executable")
  }

  BarText {
    id: program

    anchors.verticalCenter: parent.verticalCenter
    text: root.name
    weight: Font.Bold
  }

  BarText {
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, root.maxWidth - program.implicitWidth - 24)
    visible: root.title !== "" && root.title !== root.name
    text: root.title
    color: Theme.fgDim
    elide: Text.ElideRight
  }
}
