pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.controls
import qs.nix
import qs.notifications
import qs.weather

Overlay {
  id: root

  readonly property bool open: Panels.active === name
  readonly property var apps: [...new Set(Notifs.shown.map(entry => Notifs.appKey(entry)))]
  readonly property int padding: Theme.padding
  // Beside the calendar the list keeps 24em, or the calendar steps aside, as on a small screen at a large scale, or one too short for it.
  readonly property real room: width - 2 * Theme.rise - 4 * padding - 1 - side.implicitWidth
  readonly property bool besides: room >= Math.round(24 * Theme.em) && height - 2 * Theme.rise - 2 * padding >= calendar.implicitHeight

  property real shown: 0
  // Groups expanded, for Collapse all; each counts itself in and out.
  property int expandedGroups: 0

  signal hidden()
  signal collapseAll()

  onOpenChanged: {
    if (open) Notifs.hidePopups();
    else toast.dismiss();
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
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: Theme.popupTime
    easing.type: Easing.OutQuad
  }

  Card {
    id: panel

    anchors {
      top: parent.top
      topMargin: Theme.rise
      horizontalCenter: parent.horizontalCenter
    }
    radius: Theme.dateMenuRadius
    width: columns.implicitWidth + root.padding * 2
    height: columns.implicitHeight + root.padding * 2
    opacity: root.shown
    focus: true
    // BoxPointer's: a fade and a slide down from the clock by its rise.
    transform: Translate {
      y: -Theme.rise * (1 - root.shown)
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
        // A banner's 34 em, so a popup and its card here match; narrower where the screen is.
        Layout.preferredWidth: Math.min(Math.round(34 * Theme.em), root.besides ? root.room : root.width - 2 * Theme.rise - 2 * root.padding)
        spacing: root.padding

        Item {
          Layout.fillWidth: true
          // As tall as the calendar and weather at least, so the panel keeps its shape, and no taller than the screen.
          Layout.preferredHeight: Math.min(root.height - 2 * Theme.rise - 3 * root.padding - footer.implicitHeight, Math.max(side.implicitHeight - footer.implicitHeight - root.padding, list.contentHeight))

          ListView {
            id: list

            anchors.fill: parent
            spacing: Theme.padding
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

            header: Item {
              width: list.width
              height: media.active ? media.height + Theme.padding : 0

              Loader {
                id: media

                width: parent.width
                active: Media.player !== null

                sourceComponent: MediaCard {}
              }
            }

            delegate: NotificationGroup {
              id: group

              required property string modelData

              width: ListView.view.width
              entries: Notifs.shown.filter(entry => Notifs.appKey(entry) === modelData)
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
                duration: Theme.popupTime
              }

              NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1
                duration: Theme.popupTime
                easing.type: Easing.OutQuad
              }
            }

            remove: Transition {
              NumberAnimation {
                property: "opacity"
                to: 0
                duration: Theme.quickTime
              }
            }

            displaced: Transition {
              NumberAnimation {
                property: "y"
                duration: Theme.popupTime
                easing.type: Easing.OutQuad
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
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }

          EmptyLine {
            y: list.headerItem?.height ?? 0
            width: parent.width
            visible: Notifs.shown.length === 0
            text: "No Notifications"
          }
        }

        RowLayout {
          id: footer

          Layout.fillWidth: true
          Layout.leftMargin: Theme.basePadding
          spacing: Theme.padding

          // GNOME's place for it: beside Clear, under the list it quiets.
          Row {
            spacing: Theme.padding
            opacity: toast.shown ? 0 : 1

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Do Not Disturb"
              color: Theme.fg
              font: Theme.body
            }

            Switch {
              objectName: "switch:dnd"
              anchors.verticalCenter: parent.verticalCenter
              checked: Notifs.dnd
              focusable: true
              enabled: !toast.shown
              onClicked: Notifs.dnd = !Notifs.dnd
            }
          }

          Item {
            Layout.fillWidth: true

            Toast {
              id: toast

              // Centred on the whole footer, over the buttons it hides.
              x: (footer.width - width) / 2 - parent.x
              anchors.verticalCenter: parent.verticalCenter
              text: "Notifications cleared"
              action: "Undo"
              onActed: Notifs.unhold()
              onExpired: Notifs.release()
            }
          }

          Button {
            text: "Collapse All"
            pill: true
            opacity: root.expandedGroups > 0 && !toast.shown ? 1 : 0
            enabled: opacity === 1
            onClicked: root.collapseAll()
          }

          Button {
            objectName: "action:Clear"
            text: "Clear"
            pill: true
            // Hidden without leaving the layout, so the footer keeps its height.
            opacity: Notifs.shown.length > 0 && !toast.shown ? 1 : 0
            enabled: opacity === 1
            onClicked: {
              Notifs.hold();
              toast.show();
            }
          }
        }
      }

      Rectangle {
        Layout.fillHeight: true
        visible: root.besides
        implicitWidth: 1
        color: Theme.separator
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
          visible: Weather.now !== null && root.height - 2 * Theme.rise - 2 * root.padding - calendar.implicitHeight - side.spacing >= forecast.implicitHeight
        }
      }
    }
  }
}
