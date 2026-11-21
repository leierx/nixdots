pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Shell's %tooltip, under what it names, or above it where there is no room below; a layer of its own on each screen, taking no input.
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
        readonly property bool below: target.y + target.height + Theme.rise + height <= window.height - Theme.rise

        x: Math.max(Theme.rise, Math.min(window.width - width - Theme.rise, target.x + (target.width - width) / 2))
        y: below ? target.y + target.height + Theme.rise : target.y - height - Theme.rise
        width: label.implicitWidth + 2 * Theme.padding
        height: label.implicitHeight + 2 * Theme.basePadding
        radius: height / 2
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.tooltipBorder

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
