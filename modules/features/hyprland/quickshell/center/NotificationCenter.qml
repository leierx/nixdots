pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.notifications
import qs.weather

Overlay {
  id: root

  readonly property bool open: Panels.active === name
  readonly property var apps: [...new Set(Notifs.entries.map(entry => Notifs.appKey(entry)))]
  readonly property int padding: Theme.padding
  // Beside the calendar the list keeps 24em, or the calendar steps aside, as on a small screen at a large scale, or one too short for it.
  readonly property real room: width - 2 * Theme.gap - 4 * padding - 1 - side.implicitWidth
  readonly property bool besides: room >= Math.round(24 * Theme.em) && height - 2 * Theme.gap - 2 * padding >= calendar.implicitHeight

  property real shown: 0
  // Groups expanded, for Collapse all; each counts itself in and out.
  property int expandedGroups: 0

  signal hidden()
  signal collapseAll()

  onOpenChanged: {
    if (open) Notifs.hidePopups();
    (open ? closing : opening).stop();
    // Closed before it moved, it has nothing to animate, and would never report itself hidden.
    if (!open && shown === 0) Qt.callLater(root.hideClosed);
    else (open ? opening : closing).start();
  }
  onShownChanged: if (shown === 0 && !open) hidden()
  // A window Hyprland has closed stays closed, so the next open needs a new one.
  onClosed: hidden()
  Component.onCompleted: {
    Notifs.hidePopups();
    if (open) opening.start();
    else Qt.callLater(root.hideClosed);
  }

  function hideClosed(): void {
    if (!root.open) root.hidden();
  }

  name: "center"
  card: panel
  // Below the bar rather than over it.
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  // While closing, clicks already go to the windows below.
  mask: open ? null : nothing

  WlrLayershell.namespace: "quickshell:center"
  WlrLayershell.keyboardFocus: open ? root.keyboard : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  // Not a Behavior: one whose duration follows `open` may start before that duration updates.
  NumberAnimation {
    id: opening

    target: root
    property: "shown"
    to: 1
    duration: Theme.open
    easing.type: Easing.OutQuint
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: Theme.close
    easing.type: Easing.InCubic
  }

  Card {
    id: panel

    anchors {
      top: parent.top
      topMargin: Theme.gap
      horizontalCenter: parent.horizontalCenter
    }
    width: columns.implicitWidth + root.padding * 2
    height: columns.implicitHeight + root.padding * 2
    opacity: root.shown
    focus: true
    // Grown out of the clock, as the control centre grows out of its button.
    transform: Scale {
      origin.x: panel.width / 2
      origin.y: -Theme.gap
      xScale: 0.9 + 0.1 * root.shown
      yScale: 0.9 + 0.1 * root.shown
    }

    RowLayout {
      id: columns

      anchors {
        top: parent.top
        left: parent.left
        margins: root.padding
      }
      spacing: root.padding

      ColumnLayout {
        Layout.alignment: Qt.AlignTop
        // Wider than GNOME Shell's 29em message list, which read long and narrow beside the calendar; narrower where the screen is.
        Layout.preferredWidth: Math.min(Math.round(40 * Theme.em), root.besides ? root.room : root.width - 2 * Theme.gap - 2 * root.padding)
        spacing: root.padding

        Item {
          Layout.fillWidth: true
          // As tall as the calendar and weather at least, so the panel keeps its shape, and no taller than the screen.
          Layout.preferredHeight: Math.min(root.height - 2 * Theme.gap - 3 * root.padding - footer.implicitHeight, Math.max(side.implicitHeight - footer.implicitHeight - root.padding, list.contentHeight))

          ListView {
            id: list

            anchors.fill: parent
            spacing: 6
            clip: true
            flickableDirection: Flickable.VerticalFlick
            maximumFlickVelocity: 3500
            QQC.ScrollIndicator.vertical: ScrollBar {
              held: scroll.running
            }
            // Every group stays created, so one expanded keeps its state.
            cacheBuffer: 100000
            model: ScriptModel {
              values: root.apps
            }

            delegate: NotificationGroup {
              id: group

              required property string modelData

              width: ListView.view.width
              entries: Notifs.entries.filter(entry => Notifs.appKey(entry) === modelData)
              onExpandedChanged: root.expandedGroups += expanded ? 1 : -1
              Component.onDestruction: if (expanded) root.expandedGroups--

              Connections {
                target: root

                function onCollapseAll(): void {
                  group.expanded = false;
                }
              }
            }

            add: Transition {
              NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.move
              }

              NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1
                duration: Theme.move
                easing.type: Easing.OutCubic
              }
            }

            remove: Transition {
              NumberAnimation {
                property: "opacity"
                to: 0
                duration: Theme.fade
              }
            }

            displaced: Transition {
              NumberAnimation {
                property: "y"
                duration: Theme.move
                easing.type: Easing.OutCubic
              }
            }
          }

          // Qt scrolls a notch by the 15 px Wayland reports; touchpads keep the list's own scrolling.
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            // A MouseArea sets an arrow of its own, which would hide the cursors of everything under it.
            cursorShape: list.dragging ? Qt.ClosedHandCursor : undefined
            onWheel: wheel => {
              if (Math.abs(wheel.angleDelta.y) < 120) {
                wheel.accepted = false;
                return;
              }
              const bottom = list.originY + Math.max(0, list.contentHeight - list.height);
              const from = scroll.running ? scroll.to : list.contentY;
              scroll.to = Math.max(list.originY, Math.min(bottom, from - wheel.angleDelta.y));
              scroll.restart();
            }
          }

          NumberAnimation {
            id: scroll

            target: list
            property: "contentY"
            duration: Theme.move
            easing.type: Easing.OutCubic
          }

          Column {
            anchors.centerIn: parent
            visible: Notifs.entries.length === 0
            spacing: 12

            Glyph {
              anchors.horizontalCenter: parent.horizontalCenter
              path: Notifs.dnd ? Symbols.dnd : Symbols.bell
              size: 48
              color: Theme.fgDim
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "No Notifications"
              color: Theme.fgDim
              font: Theme.title4
            }
          }
        }

        RowLayout {
          id: footer

          Layout.fillWidth: true
          Layout.leftMargin: 6
          spacing: 12

          Item {
            Layout.fillWidth: true
          }

          Button {
            text: "Collapse All"
            font: Theme.body
            opacity: root.expandedGroups > 0 ? 1 : 0
            enabled: opacity === 1
            onClicked: root.collapseAll()
          }

          Button {
            text: "Clear"
            font: Theme.body
            // Hidden without leaving the layout, so the footer keeps its height.
            opacity: Notifs.entries.length > 0 ? 1 : 0
            enabled: opacity === 1
            onClicked: {
              Notifs.clear();
              Panels.close();
            }
          }
        }
      }

      Rectangle {
        Layout.fillHeight: true
        visible: root.besides
        implicitWidth: 1
        color: Theme.border
      }

      ColumnLayout {
        id: side

        Layout.alignment: Qt.AlignTop
        visible: root.besides
        spacing: root.padding

        Calendar {
          id: calendar
        }

        Forecast {
          id: forecast

          Layout.fillWidth: true
          // Left out where the screen is too short for it below the calendar.
          visible: Weather.now !== null && root.height - 2 * Theme.gap - 2 * root.padding - calendar.implicitHeight - side.spacing >= forecast.implicitHeight
        }
      }
    }
  }
}
