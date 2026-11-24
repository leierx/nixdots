pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.common
import qs.nix

Popover {
  id: root

  required property bool firmware

  signal chosen(var command)

  readonly property var tiles: [
    { title: "Lock", letter: "L", command: ["loginctl", "lock-session"], glyph: Symbols.lock },
    { title: "Suspend", letter: "S", command: ["systemctl", "suspend"], glyph: Symbols.suspend },
    { title: "Log Out", letter: "O", command: ["hyprctl", "dispatch", "hl.dsp.exit()"], glyph: Symbols.logOut, confirm: true },
    { title: "Restart", letter: "R", command: ["systemctl", "reboot"], glyph: Symbols.restart, confirm: true },
    { title: "Power Off", letter: "P", command: ["systemctl", "poweroff"], glyph: Symbols.power, confirm: true, destructive: true },
  ]
  readonly property var extras: [
    { title: "Reload Hyprland", command: ["hyprctl", "reload", "full-reset"], glyph: Symbols.reload },
    ...(root.firmware ? [{ title: "Restart to Firmware", command: ["systemctl", "reboot", "--firmware-setup"], glyph: Symbols.firmware, confirm: true }] : []),
  ]
  // The keyboard's order: the tiles, then the buttons under them.
  readonly property var actions: [...root.tiles, ...root.extras]
  readonly property var armedAction: root.actions.find(action => action.title === root.armed) ?? null

  property int current: 0
  // The title of the action waiting for a second press; a delegate's modelData is a copy, so actions go by title.
  property string armed: ""
  property var pointer: null

  function select(index: int): void {
    root.current = index;
    root.armed = "";
  }

  function indexOf(action: var): int {
    return root.actions.findIndex(other => other.title === action.title);
  }

  // Ending the session or the machine takes a second press, so one stray key cannot.
  function trigger(action: var): void {
    if (action.confirm && root.armed !== action.title) {
      root.current = root.indexOf(action);
      root.armed = action.title;
      disarm.restart();
      return;
    }
    Panels.close();
    root.chosen(action.command);
  }

  name: "power"

  WlrLayershell.namespace: "quickshell:power"

  // Solid, over the see-through backdrop.
  component Surface: Rectangle {
    id: surface

    required property var action
    readonly property bool current: root.actions[root.current]?.title === surface.action.title
    readonly property bool armed: root.armed === surface.action.title

    color: surface.armed || surface.current && surface.action.destructive ? Theme.destructiveBg : Qt.tint(Theme.popoverBg, area.pressed ? Theme.buttonActiveBg : surface.current ? Theme.buttonCheckedBg : Theme.buttonBg)
    border.width: 1
    border.color: Theme.popoverBorder

    Behavior on color {
      ColorAnimation {
        duration: Theme.quickTime
        easing.type: Easing.OutQuad
      }
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      // The pointer takes the selection once it moves, so only one tile is lit; resting where the menu opened, it leaves the keyboard's start alone.
      onPositionChanged: mouse => {
        const at = mapToItem(null, mouse.x, mouse.y);
        if (root.pointer && (root.pointer.x !== at.x || root.pointer.y !== at.y)) root.current = root.indexOf(surface.action);
        root.pointer = at;
      }
      onClicked: root.trigger(surface.action)
    }
  }

  Timer {
    id: disarm

    interval: 5000
    onTriggered: root.armed = ""
  }

  Rectangle {
    id: backdrop

    anchors.fill: parent
    color: Theme.backdrop
    opacity: root.shown
    focus: true

    Keys.onPressed: event => {
      const count = root.actions.length;
      const letter = event.text.toUpperCase();
      const action = letter === "" ? null : root.tiles.find(action => action.letter === letter);
      if (event.key === Qt.Key_Escape) Panels.close();
      // Held, a key would arm on its press and confirm on its first repeat.
      else if (event.isAutoRepeat && (action || [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].includes(event.key))) {}
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.trigger(root.actions[root.current]);
      else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) root.select((root.current + 1) % count);
      else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) root.select((root.current + count - 1) % count);
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
                  textFormat: Text.PlainText
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
          text: !root.armedAction ? " " : root.armedAction.letter ? `Press ${root.armedAction.letter} or Enter again to ${root.armedAction.title.toLowerCase()}` : `Click again or press Enter to ${root.armedAction.title.toLowerCase()}`
          textFormat: Text.PlainText
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
                  textFormat: Text.PlainText
                  color: Theme.fg
                  font: Theme.body
                }
              }
            }
          }
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: [Machine.hostname, Machine.uptime.toLowerCase(), "Esc to cancel"].filter(part => part !== "").join(" · ")
          color: Theme.fgDim
          font: Theme.body
        }
      }
    }
  }
}
