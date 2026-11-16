pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

PanelWindow {
  id: root

  required property QsMenuHandle menu
  required property point anchor
  // Submenus entered, innermost last; an entry the app has since dropped turns null.
  property list<QsMenuEntry> path: []
  readonly property QsMenuEntry submenu: path[path.length - 1] ?? null
  readonly property int padding: 6
  // Without the stray separators apps leave around items they hide.
  readonly property var entries: {
    const entries = [];
    for (const entry of opener.children.values) {
      if (!entry.isSeparator || (entries.length > 0 && !entries[entries.length - 1].isSeparator)) entries.push(entry);
    }
    if (entries.length > 0 && entries[entries.length - 1].isSeparator) entries.pop();
    return entries;
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
  WlrLayershell.namespace: "quickshell:menu"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  // Holds the root menu, since Quickshell unloads its submenus once no opener has it.
  QsMenuOpener {
    menu: root.menu
  }

  QsMenuOpener {
    id: opener

    menu: root.submenu ?? root.menu
  }

  Timer {
    interval: 1000
    running: hover.entered && !hover.hovered
    onTriggered: Panels.close()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
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

    HoverHandler {
      id: hover

      // So a menu the pointer never reached stays open.
      property bool entered: false

      onHoveredChanged: {
        if (hovered) entered = true;
      }
    }

    // Keeps clicks between the rows from closing it.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    ColumnLayout {
      id: rows

      anchors {
        fill: parent
        margins: root.padding
      }
      spacing: 0

      Rectangle {
        Layout.fillWidth: true
        implicitWidth: title.implicitWidth + 64
        implicitHeight: 32
        visible: root.submenu !== null
        radius: 6
        color: backHover.hovered ? Theme.hover : "transparent"

        ExpanderArrow {
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          rotation: 90
        }

        Text {
          id: title

          anchors.centerIn: parent
          text: root.submenu?.text ?? ""
          color: Theme.fg
          font: Theme.heading
        }

        // A hovering MouseArea would take hover from the menu's own handler.
        HoverHandler {
          id: backHover
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.path = root.path.slice(0, -1)
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        implicitHeight: 1
        visible: root.submenu !== null
        color: Theme.border
      }

      Repeater {
        model: ScriptModel {
          values: root.entries
        }

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
            color: entryHover.hovered && entry.modelData.enabled ? Theme.hover : "transparent"

            Row {
              id: content

              x: 12
              anchors.verticalCenter: parent.verticalCenter
              spacing: 8
              opacity: entry.modelData.enabled ? 1 : 0.5

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

            HoverHandler {
              id: entryHover
            }

            MouseArea {
              anchors.fill: parent
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
