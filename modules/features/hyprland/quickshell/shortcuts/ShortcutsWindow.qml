pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common

// GTK's shortcuts window: groups of rows, a description and its keys, in balanced columns.
PanelWindow {
  id: root

  required property var groups
  readonly property int columnWidth: Math.round(24 * Theme.em)
  readonly property int rowHeight: 34
  readonly property int columnCount: Math.max(1, Math.min(3, Math.floor((width - 2 * Theme.gap - 48) / (columnWidth + 32))))
  // Each group to the shortest column so far, its title counting as a row and a half.
  readonly property var columns: {
    const columns = Array.from({ length: root.columnCount }, () => ({ groups: [], size: 0 }));
    for (const group of root.groups) {
      const shortest = columns.reduce((best, column) => column.size < best.size ? column : best);
      shortest.groups.push(group);
      shortest.size += group.rows.length + 1.5;
    }
    return columns.filter(column => column.groups.length > 0);
  }

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:shortcuts"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  component Keycap: Rectangle {
    id: keycap

    required property string modelData

    implicitWidth: Math.max(implicitHeight, label.implicitWidth + 14)
    implicitHeight: 24
    radius: 6
    color: Theme.button

    Text {
      id: label

      anchors.centerIn: parent
      text: keycap.modelData
      color: Theme.fg
      font: Theme.caption
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  Rectangle {
    anchors.centerIn: parent
    width: Math.min(content.implicitWidth + 48, root.width - 2 * Theme.gap)
    height: Math.min(content.implicitHeight + 48, root.height - 2 * Theme.gap)
    radius: Theme.windowRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline
    focus: true
    clip: true

    Keys.onEscapePressed: Panels.close()

    Shadow {}

    // Keeps clicks on the card from closing it.
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: 20
      }
      spacing: 18

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Keyboard Shortcuts"
        color: Theme.fg
        font: Theme.title4
      }

      RowLayout {
        spacing: 32

        Repeater {
          model: root.columns

          ColumnLayout {
            id: column

            required property var modelData

            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.columnWidth
            spacing: 18

            Repeater {
              model: column.modelData.groups

              ColumnLayout {
                id: group

                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                Text {
                  Layout.bottomMargin: 6
                  text: group.modelData.title
                  color: Theme.fgDim
                  font: Theme.heading
                }

                Repeater {
                  model: group.modelData.rows

                  RowLayout {
                    id: row

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.rowHeight
                    spacing: 12

                    Text {
                      Layout.fillWidth: true
                      text: row.modelData.title
                      color: Theme.fg
                      font: Theme.body
                      elide: Text.ElideRight
                    }

                    // A sequence, Super X then L, as its chords one after another.
                    Repeater {
                      model: row.modelData.keys

                      RowLayout {
                        id: chord

                        required property var modelData
                        required property int index

                        spacing: 4

                        Text {
                          visible: chord.index > 0
                          text: "then"
                          color: Theme.fgDim
                          font: Theme.caption
                        }

                        Repeater {
                          model: chord.modelData

                          Keycap {}
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
