pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.common

Item {
  id: root

  required property HyprlandMonitor monitor
  // Not monitor.focused: Quickshell binds it only on monitors added after it started.
  readonly property bool focused: monitor !== null && Hyprland.focusedMonitor === monitor
  readonly property var own: {
    if (!monitor || monitor.id < 0) return [];
    const first = monitor.id * WorkspaceOwners.perMonitor + 1;
    return Array.from({ length: WorkspaceOwners.perMonitor }, (_, i) => first + i);
  }
  readonly property var foreign: !monitor ? [] : Hyprland.workspaces.values
    .filter(ws => ws.monitor === monitor && !ws.name.startsWith("special:") && !own.includes(ws.id))
    .sort((a, b) => (b.id > 0) - (a.id > 0) || a.id - b.id || a.name.localeCompare(b.name))
  // As the bar shows them, which is also the order the wheel goes through.
  readonly property var targets: [...own.map(id => String(id)), ...foreign.map(ws => ws.id > 0 ? String(ws.id) : `name:${ws.name}`)]
  readonly property string shownTarget: {
    const ws = monitor?.activeWorkspace;
    return !ws ? "" : ws.id > 0 ? String(ws.id) : `name:${ws.name}`;
  }
  function go(target: string): void {
    Panels.close();
    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(target)} })`);
  }

  // Where the wheel sent it last, until Hyprland says it is there: a fast scroll's notches come before its events.
  property string heading: ""
  onShownTargetChanged: if (shownTarget === heading) heading = ""

  // Stopping at the ends.
  function scroll(steps: int): void {
    if (steps === 0) return;
    const from = heading !== "" ? heading : shownTarget;
    const at = targets.indexOf(from);
    const next = Math.max(0, Math.min(targets.length - 1, (at < 0 ? 0 : at) - steps));
    if (targets[next] === from) return;
    heading = targets[next] === shownTarget ? "" : targets[next];
    arrival.restart();
    go(targets[next]);
  }

  // One Hyprland refuses never arrives.
  Timer {
    id: arrival

    interval: 1000
    onTriggered: root.heading = ""
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  WheelSteps {
    id: notches
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => root.scroll(notches.steps(event))
  }

  // Yours a bare number in a square a little rounded, filled while shown or under the pointer; another monitor's outlined and named after it (DP2-1).
  component Workspace: Rectangle {
    id: button

    property HyprlandWorkspace workspace: null
    property string target: ""
    property string label: ""
    property bool mine: true
    readonly property bool shown: workspace !== null && root.monitor?.activeWorkspace === workspace
    readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
    readonly property bool urgent: workspace?.urgent ?? false
    readonly property bool filled: shown && !mine
    // A step darker on a monitor without focus.
    readonly property color bright: root.focused ? Theme.fg : Theme.fgDim

    anchors.verticalCenter: parent?.verticalCenter
    width: Math.max(mine ? Theme.barItemHeight : 20, text.implicitWidth + 14)
    height: mine ? Theme.barItemHeight : 20
    radius: Theme.workspaceRadius
    color: {
      if (filled) return bright;
      if (shown) return area.containsMouse ? Theme.panelActiveHoverBg : root.focused ? Theme.panelActiveBg : Theme.panelHoverBg;
      if (area.containsMouse) return Theme.panelHoverBg;
      return "transparent";
    }
    border.width: mine ? 0 : 1
    border.color: Theme.fgDim

    Behavior on color {
      ColorAnimation {
        duration: Theme.panelButtonTime
        easing.type: Easing.OutQuad
      }
    }

    Text {
      id: text

      anchors.centerIn: parent
      text: button.label
      color: {
        if (button.filled) return Theme.panelBg;
        if (button.urgent) return Theme.destructive;
        if (area.containsMouse) return Theme.fg;
        if (button.shown) return button.bright;
        if (button.occupied) return root.focused ? Theme.fgStrong : Theme.fgDim;
        return Theme.fgFaint;
      }
      font: button.mine ? Theme.numericSemiBold : Theme.captionHeading

      // With the fill, so a number never snaps while its square fades.
      Behavior on color {
        ColorAnimation {
          duration: Theme.panelButtonTime
          easing.type: Easing.OutQuad
        }
      }
    }

    // As tall as the bar and across the gaps either side.
    MouseArea {
      id: area

      anchors.centerIn: parent
      width: parent.width + (button.mine ? 2 : 4)
      height: root.height
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      // On press, which feels quicker than a click.
      onPressed: root.go(button.target)
    }

    TooltipArea {
      text: `Workspace ${button.label}`
    }
  }

  Row {
    id: row

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.basePadding

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      // It does nothing: no button, no hover. In a workspace's square, so it keeps their rhythm, set a little apart from them.
      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.barItemHeight + 3
        height: Theme.barItemHeight

        IconImage {
          x: (Theme.barItemHeight - width) / 2
          anchors.verticalCenter: parent.verticalCenter
          implicitSize: 22
          source: Machine.icon
        }
      }

      Repeater {
        model: root.own

        Workspace {
          required property int modelData

          target: String(modelData)
          label: String(WorkspaceOwners.index(modelData))
          workspace: Hyprland.workspaces.values.find(ws => ws.id === modelData) ?? null
        }
      }
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Repeater {
        model: root.foreign

        Workspace {
          required property HyprlandWorkspace modelData

          mine: false
          workspace: modelData
          target: modelData?.id > 0 ? String(modelData.id) : `name:${modelData?.name}`
          label: modelData ? WorkspaceOwners.label(modelData, root.monitor) : ""
        }
      }
    }
  }
}
