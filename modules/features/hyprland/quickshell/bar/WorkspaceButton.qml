import QtQuick
import Quickshell.Hyprland
import qs.common

Rectangle {
  id: root

  required property string address
  required property HyprlandMonitor monitor
  required property bool foreign

  // Null for one of the monitor's own that Hyprland has not created yet.
  readonly property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(ws => ws.address === address) ?? null
  readonly property int number: Number(address) || 0
  readonly property bool shown: workspace !== null && workspace.active && workspace.monitor === monitor
  readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
  readonly property bool urgent: workspace?.urgent ?? false

  implicitWidth: Math.max(27, label.implicitWidth + 12)
  implicitHeight: 26
  // libadwaita's button corners, scaled to its size.
  radius: 7
  color: shown ? Theme.buttonChecked : area.containsMouse ? Theme.buttonHover : "transparent"
  border.width: foreign ? 1 : 0
  border.color: Theme.border

  Behavior on color {
    ColorAnimation {
      duration: 150
    }
  }

  BarText {
    id: label

    // Centred on its ink: a digit sits off-centre in its line box.
    x: (root.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x
    y: (root.height - ink.tightBoundingRect.height) / 2 - ink.tightBoundingRect.y - baselineOffset
    text: !root.foreign ? WorkspaceOwners.index(root.number) : root.number > 0 ? WorkspaceOwners.foreignLabel(root.number) : root.workspace?.name ?? root.address
    color: root.urgent ? Theme.destructive : Theme.fg
    opacity: root.occupied ? 1 : 0.4
    weight: Font.Bold
  }

  TextMetrics {
    id: ink

    font: label.font
    text: label.text
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    // On press, which feels quicker than a click.
    onPressed: {
      Panels.close();
      Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(root.number > 0 ? root.address : "name:" + root.address)} })`);
    }
  }
}
