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

Popover {
  id: root

  // While open, a group keeps its place as its notifications go, so a dismissal never moves the one under the pointer; a new app comes in on top, and each open sorts them afresh.
  property var apps: []
  readonly property int padding: Theme.padding
  // Beside the calendar the list keeps 24em, or the calendar steps aside, as on a small screen at a large scale, or one too short for it.
  readonly property real room: width - 2 * Theme.rise - 4 * padding - 1 - side.implicitWidth
  readonly property bool besides: room >= Math.round(24 * Theme.em) && height - 2 * Theme.rise - 2 * padding >= calendar.implicitHeight

  // Groups expanded, for Collapse all; each counts itself in and out.
  property int expandedGroups: 0

  signal collapseAll()
  signal clearAll()

  function arrange(fresh: bool): void {
    const keys = [...Notifs.byApp.keys()];
    if (fresh || !root.open) {
      root.apps = keys;
      return;
    }
    const kept = root.apps.filter(key => Notifs.byApp.has(key));
    root.apps = [...keys.filter(key => !kept.includes(key)), ...kept];
  }

  Connections {
    target: Notifs

    function onByAppChanged(): void {
      root.arrange(false);
    }
  }

  onOpenChanged: {
    if (!open) return;
    arrange(true);
    Notifs.hidePopups();
  }
  Component.onCompleted: {
    arrange(true);
    Notifs.hidePopups();
  }

  card: panel
  // Below the bar rather than over it.
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  WlrLayershell.namespace: "quickshell:center"

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
        // 38 em, past a banner's 34, as the user found the list narrow; narrower where the screen is.
        Layout.preferredWidth: Math.min(Math.round(38 * Theme.em), root.besides ? root.room : root.width - 2 * Theme.rise - 2 * root.padding)
        spacing: root.padding

        Item {
          Layout.fillWidth: true
          // As tall as the calendar and weather at least, so the panel keeps its shape, and no taller than the screen; eased once open, so the footer moves rather than jumps.
          property real wanted: Math.min(root.height - 2 * Theme.rise - 3 * root.padding - footer.implicitHeight, Math.max(side.implicitHeight - footer.implicitHeight - root.padding, list.contentHeight, Notifs.entries.length === 0 ? empty.y + empty.implicitHeight : 0))
          property real eased: wanted

          Behavior on eased {
            enabled: root.shown === 1

            NumberAnimation {
              duration: Theme.popupTime
              easing.type: Easing.OutQuad
            }
          }

          Layout.preferredHeight: eased

          ListView {
            id: list

            anchors.fill: parent
            spacing: Theme.padding
            clip: true
            flickableDirection: Flickable.VerticalFlick
            // Held still until it has more than fits, and never pulled past its ends.
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
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
              clip: true

              Behavior on height {
                enabled: root.shown === 1

                NumberAnimation {
                  duration: Theme.popupTime
                  easing.type: Easing.OutQuad
                }
              }

              Loader {
                id: media

                width: parent.width
                active: Media.player !== null
                opacity: 0
                onLoaded: arrive.start()

                sourceComponent: MediaCard {}

                NumberAnimation {
                  id: arrive

                  target: media
                  property: "opacity"
                  from: 0
                  to: 1
                  duration: Theme.popupTime
                  easing.type: Easing.OutQuad
                }
              }
            }

            delegate: NotificationGroup {
              id: group

              required property string modelData

              width: ListView.view.width
              entries: Notifs.byApp.get(modelData) ?? []
              onExpandedChanged: root.expandedGroups += expanded ? 1 : -1
              Component.onDestruction: if (expanded) root.expandedGroups--

              Connections {
                target: root

                function onCollapseAll(): void {
                  group.expanded = false;
                }

                // A group out of view has no slide to watch.
                function onClearAll(): void {
                  if (group.y + group.height > list.contentY && group.y < list.contentY + list.height) group.slideAway(false);
                  else group.dismiss();
                }
              }
            }

            add: Transition {
              NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.popupTime
                easing.type: Easing.OutQuad
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
                easing.type: Easing.OutQuad
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

          EmptyState {
            id: empty

            y: list.headerItem?.height ?? 0
            width: parent.width
            height: parent.height - y
            // Once the last group has gone, rather than over it as it fades.
            opacity: Notifs.entries.length === 0 && list.count === 0 ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
              NumberAnimation {
                duration: Theme.popupTime
                easing.type: Easing.OutQuad
              }
            }
            glyph: Symbols.bell
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
              onClicked: Notifs.dnd = !Notifs.dnd
            }
          }

          Item {
            Layout.fillWidth: true
          }

          Button {
            objectName: "action:Collapse All"
            text: "Collapse All"
            pill: true
            opacity: root.expandedGroups > 0 ? 1 : 0
            enabled: opacity === 1
            onClicked: root.collapseAll()
          }

          Button {
            objectName: "action:Clear"
            text: "Clear"
            pill: true
            // Hidden without leaving the layout, so the footer keeps its height.
            opacity: Notifs.entries.length > 0 ? 1 : 0
            enabled: opacity === 1
            onClicked: root.clearAll()
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
