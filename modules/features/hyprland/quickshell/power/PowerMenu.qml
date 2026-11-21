pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.nix

Overlay {
  id: root

  required property string host
  required property real uptime
  required property bool firmware

  readonly property var tiles: [
    { title: "Lock", letter: "L", command: ["loginctl", "lock-session"], glyph: Symbols.lock },
    { title: "Suspend", letter: "S", command: ["systemctl", "suspend"], glyph: Symbols.suspend },
    { title: "Log Out", letter: "O", command: ["hyprctl", "dispatch", "hl.dsp.exit()"], glyph: Symbols.logOut, confirm: true },
    { title: "Restart", letter: "R", command: ["systemctl", "reboot"], glyph: Symbols.restart, confirm: true },
    { title: "Power Off", letter: "P", command: ["systemctl", "poweroff"], glyph: Symbols.power, confirm: true, destructive: true },
  ]
  readonly property var extras: [
    { title: "Reload Hyprland",command: ["hyprctl", "reload", "full-reset"], glyph: Symbols.reload },
    ...(root.firmware ? [{ title: "Restart to Firmware",command: ["systemctl", "reboot", "--firmware-setup"], glyph: Symbols.firmware, confirm: true }] : []),
  ]
  readonly property var armedAction: [...root.tiles, ...root.extras].find(action => action.title === root.armed) ?? null

  property int current: 0
  // The title of the action waiting for a second press; a delegate's modelData is a copy, so actions go by title.
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
    if (action.confirm && root.armed !== action.title) {
      const tile = root.tiles.findIndex(other => other.title === action.title);
      if (tile !== -1)
        root.current = tile;
      root.armed = action.title;
      return;
    }
    Panels.close();
    Quickshell.execDetached(action.command);
  }

  name: "power"

  WlrLayershell.namespace: "quickshell:power"

  // Solid, over the see-through backdrop.
  component Surface: Rectangle {
    id: surface

    required property var action
    readonly property bool current: root.tiles[root.current]?.title === surface.action.title
    readonly property bool armed: root.armed === surface.action.title
    readonly property bool hovered: area.containsMouse

    color: surface.armed || surface.current && surface.action.destructive ? Theme.destructiveBg : Qt.tint(Theme.popoverBg, surface.current ? Theme.buttonCheckedBg : surface.hovered ? Theme.buttonHoverBg : Theme.buttonBg)
    border.width: 1
    border.color: Theme.popoverBorder

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
    color: Theme.backdrop
    opacity: 0
    focus: true

    Component.onCompleted: opacity = 1

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.quickTime
        easing.type: Easing.OutCubic
      }
    }

    Keys.onPressed: event => {
      const tiles = root.tiles.length;
      const letter = event.text.toUpperCase();
      const action = letter === "" ? null : root.tiles.find(action => action.letter === letter);
      if (event.key === Qt.Key_Escape) Panels.close();
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.trigger(root.tiles[root.current]);
      else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) root.select((root.current + 1) % tiles);
      else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) root.select((root.current + tiles - 1) % tiles);
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
        font: Theme.display
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
                  size: 64
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: tile.armed ? `${tile.modelData.title}?` : tile.modelData.title
                  color: Theme.fg
                  font: Theme.heading
                }
              }

              // Its key, pressed without Alt (ours: GNOME's end-session dialog shows no keys).
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
          text: !root.armedAction ? " " : root.armedAction.letter ? `Press ${root.armedAction.letter} or Enter again to ${root.armedAction.title.toLowerCase()}` : `Click again to ${root.armedAction.title.toLowerCase()}`
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
              radius: Theme.baseRadius

              RowLayout {
                id: extraRow

                anchors.centerIn: parent
                spacing: 10

                Glyph {
                  path: extra.modelData.glyph
                  size: 16
                }

                Text {
                  text: extra.armed ? `${extra.modelData.title}?` : extra.modelData.title
                  color: Theme.fg
                  font: Theme.body
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
