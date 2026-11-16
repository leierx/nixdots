import QtQuick
import Quickshell.Hyprland
import qs.common

// One workspace, by its number on its own monitor, else as "DP2-1" or by
// name. Dim while empty, filled while shown, outlined when it belongs to
// another monitor.
Rectangle {
  id: root

  required property string address
  required property HyprlandMonitor monitor
  required property bool foreign

  // Null for one of the monitor's own that Hyprland has not created yet.
  readonly property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(ws => ws.address === address) ?? null
  // 0 for a named workspace.
  readonly property int number: Number(address)
  readonly property bool shown: workspace !== null && workspace.active && workspace.monitor === monitor
  readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
  readonly property bool urgent: workspace?.urgent ?? false

  implicitWidth: Math.max(27, label.implicitWidth + 12)
  implicitHeight: 26
  // libadwaita's button corners, scaled to its size.
  radius: 7
  color: shown ? Theme.overlay(0.25) : area.containsMouse ? Theme.overlay(0.15) : "transparent"
  border.width: foreign ? 1 : 0
  border.color: Theme.border

  Behavior on color {
    ColorAnimation {
      duration: 150
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: !root.foreign ? WorkspaceOwners.index(root.number) : root.number > 0 ? WorkspaceOwners.foreignLabel(root.number) : root.workspace?.name ?? root.address
    color: root.urgent ? Theme.destructive : Theme.fg
    // Dim while empty, shown or not.
    opacity: root.occupied ? 1 : 0.4
    font: Qt.font({ family: Theme.body.family, pointSize: 10, weight: Font.Bold })
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    // On press, which feels quicker than a click.
    onPressed: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(root.number > 0 ? root.address : "name:" + root.address)} })`)
  }
}
