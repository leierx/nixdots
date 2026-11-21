pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// libadwaita's tooltip, under what it names, or above it where there is no room below; a layer of its own on each screen, taking no input.
Scope {
  Variants {
    model: Screens.real

    PanelWindow {
      id: window

      required property ShellScreen modelData
      // Taken once: the screen object dangles while its monitor goes.
      property string screenName: ""

      Component.onCompleted: screenName = modelData?.name ?? ""
      screen: modelData
      visible: Tooltips.shown && Tooltips.screen === screenName
      color: "transparent"
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell:tooltip"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        readonly property rect target: Tooltips.target
        readonly property bool below: target.y + target.height + Theme.gap / 2 + height <= window.height - Theme.gap

        x: Math.max(Theme.gap, Math.min(window.width - width - Theme.gap, target.x + (target.width - width) / 2))
        y: below ? target.y + target.height + Theme.gap / 2 : target.y - height - Theme.gap / 2
        width: label.implicitWidth + 20
        height: label.implicitHeight + 12
        radius: Theme.smallRadius
        color: Theme.tooltip

        Text {
          id: label

          anchors.centerIn: parent
          text: Tooltips.text
          color: Theme.fg
          font: Theme.body
        }
      }
    }
  }
}
