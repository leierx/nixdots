pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.common
import qs.nix

Overlay {
  id: root

  name: "gallery"
  card: box
  WlrLayershell.namespace: "quickshell:gallery"

  // A piece with its state named under it.
  component Labelled: ColumnLayout {
    id: labelled

    property string label: ""
    default property alias piece: holder.data

    spacing: Theme.baseMargin

    Item {
      id: holder

      Layout.alignment: Qt.AlignHCenter
      implicitWidth: childrenRect.width
      implicitHeight: childrenRect.height
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: labelled.label
      color: Theme.fgDim
      font: Theme.caption
    }
  }

  component Section: ColumnLayout {
    id: section

    property string title: ""
    default property alias pieces: flow.data

    Layout.fillWidth: true
    spacing: Theme.basePadding

    Text {
      text: section.title
      color: Theme.fg
      font: Theme.heading
    }

    Flow {
      id: flow

      Layout.fillWidth: true
      spacing: Theme.padding
    }
  }

  Component.onCompleted: {
    Panels.keyboard = true;
    focused.forceActiveFocus();
  }

  Card {
    id: box

    anchors.centerIn: parent
    width: Math.min(parent.width - 2 * Theme.rise, 1180)
    height: Math.min(parent.height - 2 * Theme.rise, column.implicitHeight + 2 * Theme.quickSettingsPadding)
    radius: Theme.quickSettingsRadius

    Flickable {
      anchors.fill: parent
      anchors.margins: Theme.quickSettingsPadding
      contentHeight: column.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      ColumnLayout {
        id: column

        width: parent.width
        spacing: Theme.quickSettingsPadding

        Section {
          title: "Button"

          Labelled {
            label: "rest"
            Button {
              text: "Clear"
            }
          }
          Labelled {
            label: "hover"
            Button {
              text: "Clear"
              hovered: true
            }
          }
          Labelled {
            label: "pressed"
            Button {
              text: "Clear"
              pressed: true
            }
          }
          Labelled {
            label: "checked"
            Button {
              text: "Clear"
              checked: true
            }
          }
          Labelled {
            label: "disabled"
            Button {
              text: "Clear"
              enabled: false
            }
          }
          Labelled {
            label: "focused"
            Button {
              id: focused

              text: "Clear"
            }
          }
          Labelled {
            label: "pill"
            Button {
              text: "Clear"
              pill: true
            }
          }
          Labelled {
            label: "glyph, expander"
            Button {
              glyph: Symbols.settings
              text: "Settings"
              expander: true
            }
          }
          Labelled {
            label: "flat"
            Button {
              text: "Later"
              flat: true
            }
          }
          Labelled {
            label: "flat hover"
            Button {
              text: "Later"
              flat: true
              hovered: true
            }
          }
          Labelled {
            label: "suggested"
            Button {
              text: "Connect"
              suggested: true
            }
          }
          Labelled {
            label: "suggested hover"
            Button {
              text: "Connect"
              suggested: true
              hovered: true
            }
          }
          Labelled {
            label: "destructive"
            Button {
              text: "Power Off"
              destructive: true
            }
          }
        }

        Section {
          title: "IconButton"

          Labelled {
            label: "rest"
            IconButton {
              glyph: Symbols.lock
            }
          }
          Labelled {
            label: "hover"
            IconButton {
              glyph: Symbols.lock
              hovered: true
            }
          }
          Labelled {
            label: "pressed"
            IconButton {
              glyph: Symbols.lock
              pressed: true
            }
          }
          Labelled {
            label: "checked"
            IconButton {
              glyph: Symbols.lock
              checked: true
            }
          }
          Labelled {
            label: "disabled"
            IconButton {
              glyph: Symbols.lock
              enabled: false
            }
          }
          Labelled {
            label: "flat"
            IconButton {
              glyph: Symbols.volumeUp
              flat: true
            }
          }
          Labelled {
            label: "flat hover"
            IconButton {
              glyph: Symbols.volumeUp
              flat: true
              hovered: true
            }
          }
          Labelled {
            label: "small"
            IconButton {
              glyph: Symbols.close
              small: true
            }
          }
          Labelled {
            label: "suggested"
            IconButton {
              glyph: Symbols.play
              suggested: true
            }
          }
        }

        Section {
          title: "Switch, ExpanderArrow, Keycap"

          Labelled {
            label: "off"
            Switch {}
          }
          Labelled {
            label: "off hover"
            Switch {
              hovered: true
            }
          }
          Labelled {
            label: "on"
            Switch {
              checked: true
            }
          }
          Labelled {
            label: "on hover"
            Switch {
              checked: true
              hovered: true
            }
          }
          Labelled {
            label: "disabled"
            Switch {
              enabled: false
            }
          }
          Repeater {
            model: ["down", "up", "right", "left"]

            Labelled {
              required property string modelData

              label: modelData
              ExpanderArrow {
                pointing: parent.parent.modelData
              }
            }
          }
          Labelled {
            label: "keycaps"
            Row {
              spacing: Theme.baseMargin

              Keycap {
                text: "Super"
              }
              Keycap {
                text: "Shift"
              }
              Keycap {
                text: "D"
              }
            }
          }
        }

        Section {
          title: "Slider"

          Repeater {
            model: [
              { label: "rest", value: 0.4, maximum: 1 },
              { label: "hover", value: 0.7, maximum: 1, hovered: true },
              { label: "muted", value: 0.5, maximum: 1, dim: true },
              { label: "range past 100 %", value: 0.8, maximum: 1.5 },
              { label: "past 100 %", value: 1.3, maximum: 1.5 },
              { label: "disabled", value: 0.6, maximum: 1, disabled: true }
            ]

            Labelled {
              required property var modelData

              label: modelData.label
              Slider {
                width: 200
                value: parent.parent.modelData.value
                maximum: parent.parent.modelData.maximum
                dim: parent.parent.modelData.dim ?? false
                hovered: parent.parent.modelData.hovered ?? false
                enabled: !(parent.parent.modelData.disabled ?? false)
              }
            }
          }
        }

        Section {
          title: "TextField"

          Labelled {
            label: "entry"
            TextField {
              width: 220
              placeholder: "Password"
              password: true
            }
          }
          Labelled {
            label: "entry hover"
            TextField {
              width: 220
              placeholder: "Password"
              hovered: true
            }
          }
          Labelled {
            label: "entry, text"
            TextField {
              width: 220
              text: "Pixel_7128"
            }
          }
          Labelled {
            label: "search"
            TextField {
              width: 300
              search: true
              placeholder: "Type to search"
            }
          }
          Labelled {
            label: "search, text"
            TextField {
              width: 300
              search: true
              text: "firefox"
            }
          }
        }

        Section {
          title: "ListRow, EmptyLine, Toast"

          Repeater {
            model: [
              { label: "rest", title: "Speakers" },
              { label: "hover", title: "Speakers", hovered: true },
              { label: "pressed", title: "Speakers", pressed: true },
              { label: "keyboard", title: "Speakers", selected: true },
              { label: "strong", title: "Speakers", strong: true },
              { label: "disabled", title: "Speakers", disabled: true }
            ]

            Labelled {
              required property var modelData

              label: modelData.label
              ListRow {
                width: 220
                glyph: Symbols.speaker
                title: parent.parent.modelData.title
                strong: parent.parent.modelData.strong ?? false
                hovered: parent.parent.modelData.hovered ?? false
                pressed: parent.parent.modelData.pressed ?? false
                selected: parent.parent.modelData.selected ?? false
                enabled: !(parent.parent.modelData.disabled ?? false)

                Glyph {
                  path: Symbols.check
                  size: 16
                }
              }
            }
          }
          Labelled {
            label: "empty"
            EmptyLine {
              width: 220
              text: "No results"
            }
          }
          Labelled {
            label: "toast"
            Toast {
              text: "Notifications cleared"
              action: "Undo"
              Component.onCompleted: show()
              onExpired: show()
            }
          }
        }

        Section {
          title: "Type"

          Repeater {
            model: ["title1", "title2", "title3", "title4", "largeTitle", "heading", "body", "captionHeading", "caption", "monospace", "numeric"]

            Labelled {
              required property string modelData

              label: modelData
              Text {
                text: parent.parent.modelData === "monospace" ? "nixpkgs#firefox" : parent.parent.modelData === "numeric" ? "10:41 76 %" : "Quick Settings"
                color: Theme.fg
                font: Theme[parent.parent.modelData]
              }
            }
          }
        }

        Section {
          title: "Surfaces and symbols"

          Repeater {
            model: ["panelBg", "popoverBg", "cardBg", "messageBg", "osdBg", "toastBg", "subMenuBg"]

            Labelled {
              required property string modelData

              label: modelData
              Rectangle {
                width: 72
                height: 40
                radius: Theme.baseRadius
                color: Theme[parent.parent.modelData]
                border.width: 1
                border.color: Theme.separator
              }
            }
          }
          Repeater {
            model: [16, 32, 64]

            Labelled {
              required property int modelData

              label: `${modelData} px`
              Glyph {
                path: Symbols.bell
                size: parent.parent.modelData
              }
            }
          }
        }
      }
    }
  }
}
