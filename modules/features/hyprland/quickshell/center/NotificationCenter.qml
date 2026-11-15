pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.notifications
import "swipe.js" as Swipe

// The notification center, dropping down from the middle of the bar like
// GNOME's: every notification not yet dismissed on the left, grouped per app
// with the latest app first, and a calendar on the right. Escape or a click
// outside it closes it, and opening it puts away the popups. No screen is
// set, so Hyprland opens it on the focused monitor.
PanelWindow {
  id: root

  readonly property bool open: Panels.active === "center"
  // Apps in the order of their newest notification.
  readonly property var apps: [...new Set(Notifs.entries.map(entry => root.appKey(entry)))]
  readonly property int padding: 12
  readonly property int maxListHeight: 520

  // After the closing animation, for the loader to unload it.
  signal hidden()

  function appKey(entry) {
    return entry.notification.desktopEntry || entry.notification.appName;
  }

  onOpenChanged: {
    if (open) {
      Notifs.hidePopups();
      hide.stop();
      show.restart();
    } else {
      show.stop();
      hide.restart();
    }
  }
  Component.onCompleted: {
    Notifs.hidePopups();
    show.restart();
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
  // While closing, clicks already go to the windows below.
  mask: open ? null : nothing

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:center"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  ParallelAnimation {
    id: show

    NumberAnimation {
      target: panel
      property: "opacity"
      to: 1
      duration: 180
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      target: slide
      property: "y"
      to: 0
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  ParallelAnimation {
    id: hide

    onFinished: root.hidden()

    NumberAnimation {
      target: panel
      property: "opacity"
      to: 0
      duration: 120
      easing.type: Easing.InCubic
    }

    NumberAnimation {
      target: slide
      property: "y"
      to: -12
      duration: 120
      easing.type: Easing.InCubic
    }
  }

  // Everywhere outside the panel.
  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  // libadwaita's switch.
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
        duration: 200
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

  // libadwaita's text button, in regular weight.
  component Button: Rectangle {
    id: button

    property alias text: label.text

    signal clicked()

    implicitWidth: label.implicitWidth + 34
    implicitHeight: 34
    radius: Theme.buttonRadius
    color: area.containsMouse ? Theme.buttonHover : Theme.button

    Text {
      id: label

      anchors.centerIn: parent
      color: Theme.fg
      font: Theme.body
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  Rectangle {
    id: panel

    anchors {
      top: parent.top
      topMargin: Theme.gap
      horizontalCenter: parent.horizontalCenter
    }
    width: columns.implicitWidth + root.padding * 2
    height: columns.implicitHeight + root.padding * 2
    radius: Theme.windowRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline
    opacity: 0
    focus: true
    transform: Translate {
      id: slide

      y: -12
    }

    Shadow {}

    Keys.onEscapePressed: Panels.close()

    // Keeps clicks on the panel from closing it.
    MouseArea {
      anchors.fill: parent
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
        Layout.preferredWidth: 420
        spacing: root.padding

        Item {
          Layout.fillWidth: true
          // As tall as the calendar at least, so the panel keeps its shape.
          Layout.preferredHeight: Math.max(calendar.implicitHeight - footer.implicitHeight - root.padding, Math.min(list.contentHeight, root.maxListHeight))

          ListView {
            id: list

            // The group being swiped, by index, and how far.
            property int swiped: -1
            property real swipeDistance: 0

            anchors.fill: parent
            spacing: 8
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
              required property int index

              width: ListView.view.width
              entries: Notifs.entries.filter(entry => root.appKey(entry) === modelData)
              lean: Swipe.lean(index, list.swiped, list.swipeDistance, 70)
              onSwipeMoved: distance => {
                list.swiped = index;
                list.swipeDistance = distance;
              }
              onSwipeEnded: {
                list.swiped = -1;
                list.swipeDistance = 0;
              }
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

          // Qt scrolls a wheel notch by the 15 pixels Wayland reports for it;
          // this glides a fixed step a notch and bounces at the ends. Touchpads,
          // whose deltas come in small steps, go on to the list's own scrolling.
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
              if (Math.abs(wheel.angleDelta.y) < 120) {
                wheel.accepted = false;
                return;
              }
              const top = list.originY;
              const bottom = top + Math.max(0, list.contentHeight - list.height);
              const from = scroll.running ? scroll.to : list.contentY;
              const to = from - wheel.angleDelta.y;
              if ((to < top && list.contentY <= top) || (to > bottom && list.contentY >= bottom)) {
                bounce.edge = to < top ? top : bottom;
                bounce.overshoot = to < top ? -36 : 36;
                if (!bounce.running) bounce.restart();
                return;
              }
              scroll.to = Math.max(top, Math.min(bottom, to));
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

          SequentialAnimation {
            id: bounce

            property real edge
            property real overshoot

            NumberAnimation {
              target: list
              property: "contentY"
              to: bounce.edge + bounce.overshoot
              duration: 90
              easing.type: Easing.OutQuad
            }

            NumberAnimation {
              target: list
              property: "contentY"
              to: bounce.edge
              duration: 260
              easing.type: Easing.OutBack
            }
          }

          // Shows where the list is while it moves.
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

          Item {
            Layout.fillWidth: true
          }

          Button {
            text: "Clear"
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

      Calendar {
        id: calendar

        Layout.alignment: Qt.AlignTop
      }
    }
  }
}
