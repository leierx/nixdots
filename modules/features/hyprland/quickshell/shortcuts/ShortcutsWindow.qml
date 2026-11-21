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
  // The count that needs the least shrinking to fit, the most columns among those.
  readonly property var columns: {
    let best = null;
    for (let count = 3; count >= 1; count--) {
      const columns = root.arrange(count);
      const width = columns.length * (root.columnWidth + 32) + 16;
      const height = Math.max(...columns.map(column => column.size)) * root.rowHeight + 120;
      const fit = Math.min(1, (root.width - 2 * Theme.rise) / width, (root.height - 2 * Theme.rise) / height);
      if (!best || fit > best.fit + 0.001) best = { columns, fit };
    }
    return best.columns;
  }
  readonly property real fit: Math.min(1, (width - 2 * Theme.rise) / (content.implicitWidth + 48), (height - 2 * Theme.rise) / (content.implicitHeight + 48))

  // A group's title counts as a row and a half.
  function arrange(count: int): var {
    const columns = Array.from({ length: count }, () => ({ groups: [], size: 0 }));
    for (const group of root.groups) {
      const shortest = columns.reduce((best, column) => column.size < best.size ? column : best);
      shortest.groups.push(group);
      shortest.size += group.rows.length + 1.5;
    }
    return columns.filter(column => column.groups.length > 0);
  }

  name: "shortcuts"
  card: box

  WlrLayershell.namespace: "quickshell:shortcuts"

  Card {
    id: box

    anchors.centerIn: parent
    width: (content.implicitWidth + 48) * root.fit
    height: (content.implicitHeight + 48) * root.fit
    focus: true

    // Shrunk whole on a screen too small for it, rather than cut off.
    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: 20 * root.fit
      }
      spacing: 18
      scale: root.fit
      transformOrigin: Item.Top

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

                          Keycap {
                            required property string modelData

                            text: modelData
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
}
