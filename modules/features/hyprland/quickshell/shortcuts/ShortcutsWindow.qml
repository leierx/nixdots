pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common

Overlay {
  id: root

  required property var groups
  readonly property int columnWidth: Math.round(24 * Theme.em)
  readonly property int rowHeight: 34
  readonly property int columnCount: Math.max(1, Math.min(3, Math.floor((width - 2 * Theme.gap - 48) / (columnWidth + 32))))
  // A group's title counts as a row and a half.
  readonly property var columns: {
    const columns = Array.from({ length: root.columnCount }, () => ({ groups: [], size: 0 }));
    for (const group of root.groups) {
      const shortest = columns.reduce((best, column) => column.size < best.size ? column : best);
      shortest.groups.push(group);
      shortest.size += group.rows.length + 1.5;
    }
    return columns.filter(column => column.groups.length > 0);
  }

  card: box

  WlrLayershell.namespace: "quickshell:shortcuts"

  component Keycap: Rectangle {
    id: keycap

    required property string modelData

    implicitWidth: Math.max(implicitHeight, label.implicitWidth + 14)
    implicitHeight: 24
    radius: Theme.smallRadius
    color: Theme.button

    Text {
      id: label

      anchors.centerIn: parent
      text: keycap.modelData
      color: Theme.fg
      font: Theme.caption
    }
  }

  Card {
    id: box

    anchors.centerIn: parent
    width: Math.min(content.implicitWidth + 48, root.width - 2 * Theme.gap)
    height: Math.min(content.implicitHeight + 48, root.height - 2 * Theme.gap)
    focus: true
    clip: true

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
