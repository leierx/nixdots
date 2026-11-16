pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// A tray item's menu, libadwaita's popover menu hanging below its icon. A
// submenu takes the menu's place, under a row leading back. Escape or a click
// outside it, the bar included, closes it.
PanelWindow {
  id: root

  required property QsMenuHandle menu
  // The middle of the icon button's lower edge.
  required property point anchor
  // The submenus entered, innermost last.
  property list<QsMenuEntry> path: []
  readonly property int padding: 6

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:menu"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  QsMenuOpener {
    id: opener

    menu: root.path.length > 0 ? root.path[root.path.length - 1] : root.menu
  }

  // Everywhere outside the menu.
  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  Rectangle {
    x: Math.max(Theme.gap, Math.min(root.anchor.x - width / 2, root.width - width - Theme.gap))
    y: root.anchor.y + Theme.gap
    width: Math.max(180, rows.implicitWidth) + root.padding * 2
    height: rows.implicitHeight + root.padding * 2
    radius: Theme.cardRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline
    focus: true

    Shadow {}

    Keys.onEscapePressed: Panels.close()

    // Keeps clicks between the rows from closing it.
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: rows

      anchors {
        fill: parent
        margins: root.padding
      }
      spacing: 0

      // Back out of a submenu, titled with its name.
      Rectangle {
        Layout.fillWidth: true
        implicitWidth: title.implicitWidth + 64
        implicitHeight: 32
        visible: root.path.length > 0
        radius: 6
        color: back.containsMouse ? Theme.hover : "transparent"

        ExpanderArrow {
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          rotation: 90
        }

        Text {
          id: title

          anchors.centerIn: parent
          text: root.path.length > 0 ? root.path[root.path.length - 1].text : ""
          color: Theme.fg
          font: Theme.heading
        }

        MouseArea {
          id: back

          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.path = root.path.slice(0, -1)
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        implicitHeight: 1
        visible: root.path.length > 0
        color: Theme.border
      }

      Repeater {
        model: opener.children

        Item {
          id: entry

          required property QsMenuEntry modelData

          Layout.fillWidth: true
          implicitWidth: modelData.isSeparator ? 0 : content.implicitWidth + 24 + (modelData.hasChildren ? 24 : 0)
          implicitHeight: modelData.isSeparator ? 13 : 32

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            visible: entry.modelData.isSeparator
            color: Theme.border
          }

          Rectangle {
            anchors.fill: parent
            visible: !entry.modelData.isSeparator
            radius: 6
            color: area.containsMouse && entry.modelData.enabled ? Theme.hover : "transparent"

            Row {
              id: content

              x: 12
              anchors.verticalCenter: parent.verticalCenter
              spacing: 8
              opacity: entry.modelData.enabled ? 1 : 0.5

              // A check mark or a radio dot.
              Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                visible: entry.modelData.buttonType !== QsMenuButtonType.None

                Shape {
                  anchors.fill: parent
                  visible: entry.modelData.buttonType === QsMenuButtonType.CheckBox && entry.modelData.checkState === Qt.Checked
                  preferredRendererType: Shape.CurveRenderer

                  ShapePath {
                    strokeColor: Theme.fg
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                      path: [Qt.point(3, 8.5), Qt.point(6.5, 12), Qt.point(13, 4.5)]
                    }
                  }
                }

                Rectangle {
                  anchors.centerIn: parent
                  width: 6
                  height: 6
                  radius: 3
                  visible: entry.modelData.buttonType === QsMenuButtonType.RadioButton && entry.modelData.checkState === Qt.Checked
                  color: Theme.fg
                }
              }

              IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                visible: entry.modelData.icon !== ""
                source: entry.modelData.icon
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.text
                color: Theme.fg
                font: Theme.body
              }
            }

            ExpanderArrow {
              anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
              }
              visible: entry.modelData.hasChildren
              rotation: -90
            }

            MouseArea {
              id: area

              anchors.fill: parent
              hoverEnabled: true
              enabled: entry.modelData.enabled
              onClicked: {
                if (entry.modelData.hasChildren) {
                  root.path = [...root.path, entry.modelData];
                } else {
                  entry.modelData.triggered();
                  Panels.close();
                }
              }
            }
          }
        }
      }
    }
  }
}
