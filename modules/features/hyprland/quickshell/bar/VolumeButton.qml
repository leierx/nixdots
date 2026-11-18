pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// The output's volume: the wheel turns it, a right click mutes, a click opens its popup.
Item {
  id: root

  required property ShellScreen screen
  // A name per screen, as the tray's menus have.
  readonly property string panel: `volume:${screen?.name}`
  property real wheel: 0

  // Material Symbols' volume_up, volume_down, volume_mute and volume_off
  readonly property string up: "M760-481q0-83-44-151.5T598-735q-15-7-22-21.5t-2-29.5q6-16 21.5-23t31.5 0q97 43 155 131.5T840-481q0 108-58 196.5T627-153q-16 7-31.5 0T574-176q-5-15 2-29.5t22-21.5q74-34 118-102.5T760-481ZM280-360H160q-17 0-28.5-11.5T120-400v-160q0-17 11.5-28.5T160-600h120l132-132q19-19 43.5-8.5T480-703v446q0 27-24.5 37.5T412-228L280-360Zm380-120q0 42-19 79.5T591-339q-10 6-20.5.5T560-356v-250q0-12 10.5-17.5t20.5.5q31 25 50 63t19 80ZM400-606l-86 86H200v80h114l86 86v-252ZM300-480Z"
  readonly property string down: "M360-360H240q-17 0-28.5-11.5T200-400v-160q0-17 11.5-28.5T240-600h120l132-132q19-19 43.5-8.5T560-703v446q0 27-24.5 37.5T492-228L360-360Zm380-120q0 42-19 79.5T671-339q-10 6-20.5.5T640-356v-250q0-12 10.5-17.5t20.5.5q31 25 50 63t19 80ZM480-606l-86 86H280v80h114l86 86v-252ZM380-480Z"
  readonly property string mute: "M440-360H320q-17 0-28.5-11.5T280-400v-160q0-17 11.5-28.5T320-600h120l132-132q19-19 43.5-8.5T640-703v446q0 27-24.5 37.5T572-228L440-360Zm-80-80h114l86 86v-252l-86 86H360v80Zm100-40Z"
  readonly property string off: "M671-177q-11 7-22 13t-23 11q-15 7-30.5 0T574-176q-6-15 1.5-29.5T598-227q7-3 13-6.5t12-7.5L480-368v111q0 27-24.5 37.5T412-228L280-360H160q-17 0-28.5-11.5T120-400v-160q0-17 11.5-28.5T160-600h88L84-764q-11-11-11-28t11-28q11-11 28-11t28 11l680 680q11 11 11 28t-11 28q-11 11-28 11t-28-11l-93-93Zm89-304q0-83-44-151.5T598-735q-15-7-22-21.5t-2-29.5q6-16 21.5-23t31.5 0q97 43 155 131t58 197q0 33-6 65.5T817-353q-8 22-24.5 27.5t-30.5.5q-14-5-22.5-18t-.5-30q11-26 16-52.5t5-55.5ZM591-623q33 21 51 63t18 80v10q0 5-1 10-2 13-14 17t-22-6l-51-51q-6-6-9-13.5t-3-15.5v-77q0-12 10.5-17.5t20.5.5Zm-201-59q-6-6-6-14t6-14l22-22q19-19 43.5-8.5T480-703v63q0 14-12 19t-22-5l-56-56Zm10 328v-94l-72-72H200v80h114l86 86Zm-36-130Z"
  readonly property string glyph: Volume.muted ? off : Volume.volume <= 0.001 ? mute : Volume.volume < 0.5 ? down : up

  visible: Volume.present
  implicitWidth: content.implicitWidth + 16
  implicitHeight: 26

  Rectangle {
    anchors.fill: parent
    radius: Theme.smallRadius
    color: Panels.active === root.panel ? Theme.buttonChecked : area.containsMouse ? Theme.buttonHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }
  }

  Row {
    id: content

    anchors.centerIn: parent
    spacing: 5

    Glyph {
      anchors.verticalCenter: parent.verticalCenter
      path: root.glyph
      size: 18
      color: Volume.muted ? Theme.fgDim : Theme.fg
    }

    BarText {
      anchors.verticalCenter: parent.verticalCenter
      text: `${Volume.percent}%`
      color: Volume.muted ? Theme.fgDim : Theme.fg
      font.strikeout: Volume.muted
    }
  }

  MouseArea {
    id: area

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) Volume.toggleMute();
      else Panels.toggle(root.panel);
    }
    // A notch is five percent; a touchpad's small steps add up to notches.
    onWheel: event => {
      root.wheel += event.angleDelta.y || event.pixelDelta.y;
      if (Math.abs(root.wheel) < 120) return;
      Volume.setVolume(Math.round((Volume.volume + Math.sign(root.wheel) * 0.05) * 20) / 20);
      root.wheel = 0;
    }
  }

  // Under the button, on its own screen.
  LazyLoader {
    active: Panels.active === root.panel

    VolumePopup {
      screen: root.screen
      name: root.panel
      anchorX: root.mapToItem(null, root.width / 2, 0).x
      glyph: root.glyph
    }
  }
}
