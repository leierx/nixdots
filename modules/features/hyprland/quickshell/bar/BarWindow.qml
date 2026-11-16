import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

// One monitor's bar: the NixOS logo and the monitor's workspaces on the left,
// the clock in the middle, the weather, battery and tray on the right. Over
// a lone window, which Hyprland draws without gaps (rules.nix' w[tv1] and
// f[1]), it is one solid bar the window meets; otherwise its three groups
// float as islands over the gaps, and it morphs between the two.
PanelWindow {
  id: root

  // Looked up rather than Hyprland.monitorFor(), which is not a binding and
  // stays null when the output comes before Hyprland announces the monitor.
  readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
  // One tiled window, a group counting once, or a maximized one.
  readonly property bool solid: {
    const workspace = monitor?.activeWorkspace;
    if (!workspace) return false;
    return workspace.hasFullscreen || workspace.toplevels.values.filter(t => !t.lastIpcObject.floating && !t.lastIpcObject.hidden).length === 1;
  }
  readonly property int barHeight: 34
  // From the islands to the screen's edges.
  readonly property int inset: 6

  anchors {
    top: true
    left: true
    right: true
  }
  // The islands hang below the space the bar keeps, into the windows' gaps,
  // so turning solid does not move them; the rest is room for their shadows.
  implicitHeight: barHeight + 24
  exclusiveZone: barHeight
  mask: Region {
    width: root.width
    height: root.solid ? root.barHeight : root.barHeight + root.inset
  }
  color: "transparent"

  WlrLayershell.namespace: "quickshell:bar"

  component Morph: NumberAnimation {
    duration: 200
    easing.type: Easing.OutCubic
  }

  Rectangle {
    width: parent.width
    height: root.barHeight
    color: Theme.bg
    opacity: root.solid ? 1 : 0

    Behavior on opacity {
      Morph {}
    }
  }

  // A group of modules: part of the solid bar, or a floating card.
  component Island: Item {
    id: island

    default property alias content: row.data
    property alias spacing: row.spacing
    // Between the modules and the card's ends.
    property real padding: root.solid ? 0 : 8

    y: root.solid ? 0 : root.inset
    width: row.implicitWidth + padding * 2
    height: root.barHeight

    Behavior on x {
      Morph {}
    }

    Behavior on y {
      Morph {}
    }

    Behavior on width {
      Morph {}
    }

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: Theme.bg
      border.width: 1
      border.color: Theme.outline
      opacity: root.solid ? 0 : 1

      Behavior on opacity {
        Morph {}
      }

      Shadow {}
    }

    Row {
      id: row

      x: island.padding
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4
    }
  }

  Island {
    x: root.solid ? 0 : root.inset
    padding: root.solid ? 0 : 4

    NixLogo {
      implicitHeight: root.barHeight
    }

    Workspaces {
      anchors.verticalCenter: parent.verticalCenter
      monitor: root.monitor
    }
  }

  Island {
    x: Math.round((root.width - width) / 2)
    padding: root.solid ? 0 : 3

    Clock {
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Island {
    x: root.width - width - (root.solid ? 0 : root.inset)
    padding: root.solid ? 6 : 8
    spacing: 12

    CurrentWeather {
      anchors.verticalCenter: parent.verticalCenter
    }

    Battery {
      anchors.verticalCenter: parent.verticalCenter
    }

    Tray {
      anchors.verticalCenter: parent.verticalCenter
      screen: root.screen
    }
  }
}
