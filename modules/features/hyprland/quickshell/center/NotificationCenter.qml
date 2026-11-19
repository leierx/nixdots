pragma ComponentBehavior: Bound

import QtQuick
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

  property real shown: 0

  signal hidden()

  onOpenChanged: {
    if (open) Notifs.hidePopups();
    (open ? closing : opening).stop();
    (open ? opening : closing).start();
  }
  onShownChanged: if (shown === 0 && !open) hidden()
  // A window Hyprland has closed stays closed, so the next open needs a new one.
  onClosed: hidden()
  Component.onCompleted: {
    Notifs.hidePopups();
    if (open) opening.start();
  }

  name: "center"
  card: panel
  // Below the bar rather than over it.
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  // While closing, clicks already go to the windows below.
  mask: open ? null : nothing

  WlrLayershell.namespace: "quickshell:center"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  // Not a Behavior: one whose duration follows `open` may start before that duration updates.
  NumberAnimation {
    id: opening

    target: root
    property: "shown"
    to: 1
    duration: 180
    easing.type: Easing.OutCubic
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: 120
    easing.type: Easing.InCubic
  }

  component Switch: Rectangle {
    id: toggle

    property bool checked: false

    signal clicked()

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? Theme.accentBg : Theme.trough

    Behavior on color {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    Rectangle {
      x: toggle.checked ? toggle.width - width - 3 : 3
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      radius: width / 2
      color: toggle.checked || area.containsMouse ? Theme.fg : Theme.slider

      Behavior on x {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: toggle.clicked()
    }
  }

  // Checked often while open, so a change made elsewhere shows as it is looked at.
  Binding {
    target: Caffeine
    property: "watched"
    value: root.open
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
    transform: Translate {
      y: -12 * (1 - root.shown)
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
        // Wider than GNOME Shell's 29em message list, which read long and narrow beside the calendar.
        Layout.preferredWidth: Math.round(40 * Theme.em)
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
            // Every group stays created, so one expanded keeps its state.
            cacheBuffer: 100000
            model: ScriptModel {
              values: root.apps
            }

            delegate: NotificationGroup {
              required property string modelData

              width: ListView.view.width
              entries: Notifs.entries.filter(entry => Notifs.appKey(entry) === modelData)
            }

            add: Transition {
              NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
              }

              NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
              }
            }

            remove: Transition {
              NumberAnimation {
                property: "opacity"
                to: 0
                duration: 150
              }
            }

            displaced: Transition {
              NumberAnimation {
                property: "y"
                duration: 200
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
            duration: 200
            easing.type: Easing.OutCubic
          }

          Rectangle {
            anchors.right: parent.right
            y: list.visibleArea.yPosition * list.height
            width: 4
            height: list.visibleArea.heightRatio * list.height
            radius: width / 2
            color: Theme.fgDim
            visible: list.contentHeight > list.height
            opacity: list.moving || scroll.running ? 1 : 0

            Behavior on opacity {
              NumberAnimation {
                duration: 400
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: Notifs.entries.length === 0
            text: "No Notifications"
            color: Theme.fgDim
            font: Theme.title4
          }
        }

        RowLayout {
          id: footer

          Layout.fillWidth: true
          Layout.leftMargin: 6
          spacing: 12

          Text {
            text: "Do Not Disturb"
            color: Theme.fg
            font: Theme.body
          }

          Switch {
            checked: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
          }

          Text {
            Layout.leftMargin: 12
            text: "Caffeine"
            color: Theme.fg
            font: Theme.body
          }

          Switch {
            checked: Caffeine.active
            onClicked: Caffeine.toggle()
          }

          Item {
            Layout.fillWidth: true
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
        implicitWidth: 1
        color: Theme.border
      }

      ColumnLayout {
        id: side

        Layout.alignment: Qt.AlignTop
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
