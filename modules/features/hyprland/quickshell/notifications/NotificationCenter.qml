pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common

// The notification center: a panel dropping down from the top right corner,
// below the bar, with every notification not yet dismissed, stacked per app
// with the latest app first. Escape or a click outside it closes it, and
// opening it puts away the popups. No screen is set, so Hyprland opens it on
// the focused monitor.
PanelWindow {
  id: root

  // Apps in the order of their newest notification.
  readonly property var apps: {
    const keys = [];
    for (const entry of Notifs.entries) {
      const key = appKey(entry);
      if (!keys.includes(key)) keys.push(key);
    }
    return keys;
  }

  function appKey(entry) {
    return entry.notification.desktopEntry || entry.notification.appName;
  }

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  // Below the bar rather than over it.
  exclusiveZone: 0

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:notification-center"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  Component.onCompleted: Notifs.hidePopups()

  // Everywhere outside the panel.
  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  component Pill: Rectangle {
    id: pill

    property alias text: label.text
    property bool active: false

    signal clicked()

    implicitWidth: label.implicitWidth + Theme.px(28)
    implicitHeight: Theme.px(34)
    radius: height / 2
    color: active ? Theme.accent : area.containsMouse ? Theme.selected : Theme.raised

    Text {
      id: label

      anchors.centerIn: parent
      color: Theme.fg
      font {
        family: Theme.fontFamily
        pixelSize: Theme.fontSmall
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }

  Rectangle {
    id: panel

    anchors {
      top: parent.top
      right: parent.right
      margins: Theme.gap
    }
    width: Theme.px(480)
    height: content.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: Theme.border
    focus: true

    Keys.onEscapePressed: Panels.close()

    // Keeps clicks on the panel from closing it.
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
      }
      spacing: Theme.px(12)

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.px(4)
        spacing: Theme.px(8)

        Text {
          Layout.fillWidth: true
          text: "Notifications"
          color: Theme.fg
          font {
            family: Theme.fontFamily
            pixelSize: Theme.fontTitle
            weight: Font.DemiBold
          }
        }

        Pill {
          text: "Do not disturb"
          active: Notifs.dnd
          onClicked: Notifs.dnd = !Notifs.dnd
        }

        Pill {
          text: "Clear all"
          visible: Notifs.entries.length > 0
          onClicked: Notifs.clear()
        }
      }

      Flickable {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Theme.px(520))
        visible: Notifs.entries.length > 0
        clip: true
        contentHeight: stacks.implicitHeight
        // Only the wheel scrolls, so dragging a card swipes it away.
        interactive: false
        // Dismissing from the bottom shortens the list under the view.
        onContentHeightChanged: contentY = Math.max(0, Math.min(contentY, contentHeight - height))

        // Qt scrolls a wheel notch by the 15 pixels Wayland reports for it;
        // this moves a fixed step a notch instead. Touchpads, which send
        // scroll phases, keep their own pixels.
        WheelHandler {
          target: null
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: event => {
            const bottom = Math.max(0, list.contentHeight - list.height);
            if (event.phase !== Qt.NoScrollPhase) {
              scroll.stop();
              list.contentY = Math.max(0, Math.min(bottom, list.contentY - event.pixelDelta.y));
              return;
            }
            const from = scroll.running ? scroll.to : list.contentY;
            scroll.to = Math.max(0, Math.min(bottom, from - event.angleDelta.y / 120 * Theme.px(120)));
            scroll.restart();
          }
        }

        NumberAnimation {
          id: scroll

          target: list
          property: "contentY"
          duration: 150
          easing.type: Easing.OutCubic
        }

        ColumnLayout {
          id: stacks

          width: list.width
          spacing: Theme.px(10)

          Repeater {
            model: ScriptModel {
              values: root.apps
            }

            NotificationStack {
              required property string modelData

              Layout.fillWidth: true
              entries: Notifs.entries.filter(entry => root.appKey(entry) === modelData)
            }
          }
        }
      }

      Text {
        Layout.fillWidth: true
        Layout.topMargin: Theme.px(24)
        Layout.bottomMargin: Theme.px(24)
        visible: Notifs.entries.length === 0
        text: "No notifications"
        horizontalAlignment: Text.AlignHCenter
        color: Theme.fgDim
        font {
          family: Theme.fontFamily
          pixelSize: Theme.fontBody
        }
      }
    }
  }
}
