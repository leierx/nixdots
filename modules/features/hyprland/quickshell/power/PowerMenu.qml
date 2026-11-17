pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common

Overlay {
  id: root

  required property string host
  required property real uptime
  required property bool firmware

  // Material Symbols' lock, bedtime, logout, restart_alt and power_settings_new
  readonly property var tiles: [
    { title: "Lock", letter: "L", command: ["loginctl", "lock-session"], glyph: "M240-80q-33 0-56.5-23.5T160-160v-400q0-33 23.5-56.5T240-640h40v-80q0-83 58.5-141.5T480-920q83 0 141.5 58.5T680-720v80h40q33 0 56.5 23.5T800-560v400q0 33-23.5 56.5T720-80H240Zm0-80h480v-400H240v400Zm296.5-143.5Q560-327 560-360t-23.5-56.5Q513-440 480-440t-56.5 23.5Q400-393 400-360t23.5 56.5Q447-280 480-280t56.5-23.5ZM360-640h240v-80q0-50-35-85t-85-35q-50 0-85 35t-35 85v80ZM240-160v-400 400Z" },
    { title: "Suspend", letter: "S", command: ["systemctl", "suspend"], glyph: "M484-80q-84 0-157.5-32t-128-86.5Q144-253 112-326.5T80-484q0-128 72-232t193-146q22-8 41 5.5t18 36.5q-3 85 27 162t90 137q60 60 137 90t162 27q26-1 38.5 17.5T863-345q-44 120-147.5 192.5T484-80Zm0-80q88 0 163-44t118-121q-86-8-163-43.5T464-465q-61-61-97-138t-43-163q-77 43-120.5 118.5T160-484q0 135 94.5 229.5T484-160Zm-20-305Z" },
    { title: "Log Out", letter: "Q", command: ["hyprctl", "dispatch", "hl.dsp.exit()"], glyph: "M200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h240q17 0 28.5 11.5T480-800q0 17-11.5 28.5T440-760H200v560h240q17 0 28.5 11.5T480-160q0 17-11.5 28.5T440-120H200Zm487-320H400q-17 0-28.5-11.5T360-480q0-17 11.5-28.5T400-520h287l-75-75q-11-11-11-27t11-28q11-12 28-12.5t29 11.5l143 143q12 12 12 28t-12 28L669-309q-12 12-28.5 11.5T612-310q-11-12-10.5-28.5T613-366l74-74Z", confirm: true },
    { title: "Restart", letter: "R", command: ["systemctl", "reboot"], glyph: "M393-132q-103-29-168-113.5T160-440q0-57 19-108.5t54-94.5q11-12 27-12.5t29 12.5q11 11 11.5 27T290-586q-24 31-37 68t-13 78q0 81 47.5 144.5T410-209q13 4 21.5 15t8.5 24q0 20-14 31.5t-33 6.5Zm174 0q-19 5-33-7t-14-32q0-12 8.5-23t21.5-15q75-24 122.5-87T720-440q0-100-70-170t-170-70h-3l16 16q11 11 11 28t-11 28q-11 11-28 11t-28-11l-84-84q-6-6-8.5-13t-2.5-15q0-8 2.5-15t8.5-13l84-84q11-11 28-11t28 11q11 11 11 28t-11 28l-16 16h3q134 0 227 93t93 227q0 109-65 194T567-132Z", confirm: true },
    { title: "Power Off", letter: "P", command: ["systemctl", "poweroff"], glyph: "M480-80q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-73 24.5-138.5T172-736q11-14 26.5-13t26.5 11q11 10 14.5 26T229-679q-32 41-50.5 91.5T160-480q0 134 93 227t227 93q134 0 227-93t93-227q0-57-18.5-107.5T731-679q-14-17-10.5-33t14.5-26q11-10 26.5-11t26.5 13q43 52 67.5 117.5T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm-28.5-371.5Q440-463 440-480v-360q0-17 11.5-28.5T480-880q17 0 28.5 11.5T520-840v360q0 17-11.5 28.5T480-440q-17 0-28.5-11.5Z", confirm: true, destructive: true },
  ]
  // Material Symbols' refresh and developer_board
  readonly property var extras: [
    { title: "Reload Hyprland", letter: "H", command: ["hyprctl", "reload", "full-reset"], glyph: "M480-160q-134 0-227-93t-93-227q0-134 93-227t227-93q69 0 132 28.5T720-690v-70q0-17 11.5-28.5T760-800q17 0 28.5 11.5T800-760v200q0 17-11.5 28.5T760-520H560q-17 0-28.5-11.5T520-560q0-17 11.5-28.5T560-600h128q-32-56-87.5-88T480-720q-100 0-170 70t-70 170q0 100 70 170t170 70q68 0 124.5-34.5T692-367q8-14 22.5-19.5t29.5-.5q16 5 23 21t-1 30q-41 80-117 128t-169 48Z" },
    ...(root.firmware ? [{ title: "Restart to Firmware", letter: "F", command: ["systemctl", "reboot", "--firmware-setup"], glyph: "M160-120q-33 0-56.5-23.5T80-200v-560q0-33 23.5-56.5T160-840h560q33 0 56.5 23.5T800-760v80h40q17 0 28.5 11.5T880-640q0 17-11.5 28.5T840-600h-40v80h40q17 0 28.5 11.5T880-480q0 17-11.5 28.5T840-440h-40v80h40q17 0 28.5 11.5T880-320q0 17-11.5 28.5T840-280h-40v80q0 33-23.5 56.5T720-120H160Zm0-80h560v-560H160v560Zm120-80h120q17 0 28.5-11.5T440-320v-80q0-17-11.5-28.5T400-440H280q-17 0-28.5 11.5T240-400v80q0 17 11.5 28.5T280-280Zm240-280h80q17 0 28.5-11.5T640-600v-40q0-17-11.5-28.5T600-680h-80q-17 0-28.5 11.5T480-640v40q0 17 11.5 28.5T520-560Zm-240 80h120q17 0 28.5-11.5T440-520v-120q0-17-11.5-28.5T400-680H280q-17 0-28.5 11.5T240-640v120q0 17 11.5 28.5T280-480Zm240 200h80q17 0 28.5-11.5T640-320v-160q0-17-11.5-28.5T600-520h-80q-17 0-28.5 11.5T480-480v160q0 17 11.5 28.5T520-280ZM160-760v560-560Z", confirm: true }] : []),
  ]
  readonly property var actions: [...root.tiles, ...root.extras]
  readonly property var armedAction: root.actions.find(action => action.letter === root.armed) ?? null

  property int current: 0
  // The letter of the action waiting for a second press; a delegate's modelData is a copy, so actions go by letter.
  property string armed: ""

  readonly property string uptimeText: {
    const minutes = Math.floor(root.uptime / 60);
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor(minutes % 1440 / 60);
    const plural = (count, unit) => `${count} ${unit}${count === 1 ? "" : "s"}`;
    const parts = days > 0 ? [plural(days, "day"), plural(hours, "hour")] : hours > 0 ? [plural(hours, "hour"), plural(minutes % 60, "minute")] : [plural(minutes % 60, "minute")];
    return `up ${parts.join(", ")}`;
  }

  function select(index: int): void {
    root.current = index;
    root.armed = "";
  }

  // Ending the session or the machine takes a second press, so one stray key cannot.
  function trigger(action: var): void {
    if (action.confirm && root.armed !== action.letter) {
      root.current = root.actions.findIndex(other => other.letter === action.letter);
      root.armed = action.letter;
      return;
    }
    Panels.close();
    Quickshell.execDetached(action.command);
  }

  name: "power"

  WlrLayershell.namespace: "quickshell:power"

  component Keycap: Rectangle {
    id: keycap

    property alias text: label.text

    implicitWidth: Math.max(implicitHeight, label.implicitWidth + 10)
    implicitHeight: 22
    radius: Theme.smallRadius
    color: "transparent"
    border.width: 1
    border.color: Theme.border

    Text {
      id: label

      anchors.centerIn: parent
      color: Theme.fgDim
      font: Theme.captionHeading
    }
  }

  // Solid, over the see-through backdrop.
  component Surface: Rectangle {
    id: surface

    required property var action
    readonly property bool current: root.actions[root.current]?.letter === surface.action.letter
    readonly property bool armed: root.armed === surface.action.letter
    readonly property bool hovered: area.containsMouse

    color: surface.armed || surface.current && surface.action.destructive ? Theme.destructiveBg : Qt.tint(Theme.bg, surface.current ? Theme.buttonChecked : surface.hovered ? Theme.buttonHover : Theme.hover)
    border.width: 1
    border.color: Theme.outline

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.trigger(surface.action)
    }
  }

  Timer {
    running: root.armed !== ""
    interval: 5000
    onTriggered: root.armed = ""
  }

  Rectangle {
    id: backdrop

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.88)
    opacity: 0
    focus: true

    Component.onCompleted: opacity = 1

    Behavior on opacity {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    Keys.onPressed: event => {
      const tiles = root.tiles.length;
      const onTiles = root.current < tiles;
      const letter = event.text.toUpperCase();
      const action = letter === "" ? null : root.actions.find(action => action.letter === letter);
      if (event.key === Qt.Key_Escape) Panels.close();
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.trigger(root.actions[root.current]);
      else if (event.key === Qt.Key_Tab) root.select((root.current + 1) % root.actions.length);
      else if (event.key === Qt.Key_Backtab) root.select((root.current + root.actions.length - 1) % root.actions.length);
      else if (event.key === Qt.Key_Right) root.select(onTiles ? (root.current + 1) % tiles : tiles + (root.current - tiles + 1) % root.extras.length);
      else if (event.key === Qt.Key_Left) root.select(onTiles ? (root.current + tiles - 1) % tiles : tiles + (root.current - tiles + root.extras.length - 1) % root.extras.length);
      else if (event.key === Qt.Key_Down && onTiles) root.select(tiles + (root.current <= 2 ? 0 : root.extras.length - 1));
      else if (event.key === Qt.Key_Up && !onTiles) root.select(root.extras.length === 1 ? 2 : root.current === tiles ? 1 : 3);
      else if (action) root.trigger(action);
      else return;
      event.accepted = true;
    }

    ColumnLayout {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(parent.height * 0.16)
      spacing: 0

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(Time.now, "HH:mm")
        color: Theme.fg
        font: Qt.font({ family: Theme.body.family, pointSize: 64, weight: Font.Bold })
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(Time.now, "dddd d MMMM")
        color: Theme.fg
        font: Theme.title4
      }
    }

    Item {
      anchors.fill: parent
      anchors.topMargin: Math.round(parent.height / 2 - 34)
      anchors.bottomMargin: 48

      ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 22

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 18

          Repeater {
            model: root.tiles

            Surface {
              id: tile

              required property var modelData

              action: tile.modelData
              implicitWidth: 148
              implicitHeight: 148
              radius: 28

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                Glyph {
                  Layout.alignment: Qt.AlignHCenter
                  path: tile.modelData.glyph
                  size: 44
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: tile.armed ? `${tile.modelData.title}?` : tile.modelData.title
                  color: Theme.fg
                  font: Theme.heading
                }
              }

              Keycap {
                anchors {
                  top: parent.top
                  right: parent.right
                  margins: 12
                }
                text: tile.modelData.letter
              }
            }
          }
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          opacity: root.armedAction ? 1 : 0
          text: root.armedAction ? `Press ${root.armedAction.letter} or Enter again to ${root.armedAction.title.toLowerCase()}` : " "
          color: Theme.fg
          font: Theme.body
        }
      }

      ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 18

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 10

          Repeater {
            model: root.extras

            Surface {
              id: extra

              required property var modelData

              action: extra.modelData
              implicitWidth: extraRow.implicitWidth + 28
              implicitHeight: 38
              radius: Theme.buttonRadius

              RowLayout {
                id: extraRow

                anchors.centerIn: parent
                spacing: 10

                Glyph {
                  path: extra.modelData.glyph
                  size: 18
                }

                Text {
                  text: extra.armed ? `${extra.modelData.title}?` : extra.modelData.title
                  color: Theme.fg
                  font: Theme.body
                }

                Keycap {
                  text: extra.modelData.letter
                }
              }
            }
          }
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: `${root.host} · ${root.uptimeText} · Esc to cancel`
          color: Theme.fgDim
          font: Theme.body
        }
      }
    }
  }
}
