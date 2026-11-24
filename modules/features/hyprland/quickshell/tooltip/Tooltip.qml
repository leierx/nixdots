pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

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

      onVisibleChanged: if (visible) fade.restart()

      Rectangle {
        id: bubble

        readonly property rect target: Tooltips.target
        readonly property bool below: target.y + target.height + Theme.rise + height <= window.height - Theme.rise

        x: Math.max(Theme.rise, Math.min(window.width - width - Theme.rise, target.x + (target.width - width) / 2))
        y: below ? target.y + target.height + Theme.rise : target.y - height - Theme.rise
        width: label.width + 2 * Theme.padding
        height: label.implicitHeight + 2 * Theme.basePadding
        radius: label.lineCount > 1 ? Theme.menuItemRadius : height / 2
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.tooltipBorder

        Text {
          id: label

          anchors.centerIn: parent
          // An app's own words (a tray item's title): never markup, and never wider than a banner.
          width: Math.min(implicitWidth, Math.round(34 * Theme.em), window.width - 2 * Theme.rise - 2 * Theme.padding)
          text: Tooltips.text
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 4
          elide: Text.ElideRight
          color: Theme.fg
          font: Theme.body
        }

        NumberAnimation {
          id: fade

          target: bubble
          property: "opacity"
          from: 0
          to: 1
          duration: Theme.quickTime
          easing.type: Easing.OutQuad
        }
      }
    }
  }
}
