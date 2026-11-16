pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import "search.js" as Search

// No screen is set, so Hyprland opens it on the focused monitor.
PanelWindow {
  id: root

  required property LauncherMode mode
  readonly property bool previewing: mode.preview !== null
  readonly property bool listing: matches.count > 0
  // Clear of the screen's edges, whatever its size and scale.
  readonly property int margin: Math.round(3 * Theme.em)
  readonly property real cardWidth: Math.min(Math.round((previewing || mode.wide ? 68 : 48) * Theme.em), width - 2 * margin)
  readonly property int fieldHeight: 68
  readonly property int rows: Math.max(1, Math.min(8, Math.floor((height - 2 * margin - fieldHeight - 17) / (matches.rowHeight + matches.spacing))))
  // A preview keeps the card's height, whatever the matches.
  readonly property int resultsHeight: (previewing ? rows * matches.rowHeight + (rows - 1) * matches.spacing : matches.implicitHeight) + 16
  // Until the window has its size, the card would glide in from the top.
  property bool settled: false

  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  // Cover the bar rather than being pushed aside by it.
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell:launcher"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  // Material Symbols draw in a 960 px box above the origin.
  component Glyph: Item {
    id: glyph

    required property string path
    property int size: 20
    property color color: Theme.fg

    implicitWidth: size
    implicitHeight: size

    Shape {
      y: glyph.size
      width: 960
      height: 960
      scale: glyph.size / 960
      transformOrigin: Item.TopLeft
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: glyph.color
        strokeColor: "transparent"
        fillRule: ShapePath.WindingFill

        PathSvg {
          path: glyph.path
        }
      }
    }
  }

  // What the query matched in bold, as rofi does.
  component Marked: Text {
    id: marked

    required property string query
    required property string plain
    property bool loose: false
    readonly property bool marking: marked.query.trim() !== ""

    text: marked.marking ? Search.mark(marked.query, marked.plain, marked.loose) : marked.plain
    textFormat: marked.marking ? Text.StyledText : Text.PlainText
    elide: Text.ElideRight
    maximumLineCount: 1
  }

  component SearchField: TextInput {
    id: field

    required property ResultList list
    readonly property LauncherMode mode: field.list.mode

    focus: true
    color: Theme.fg
    selectionColor: Theme.accentBg
    selectedTextColor: Theme.accentFg
    font.family: Theme.body.family
    font.pointSize: 19
    // The default cursor blinks; this one stays lit.
    cursorDelegate: Rectangle {
      width: 1
      color: field.color
      visible: field.cursorVisible
    }

    // Another mode's shortcut while open starts it afresh.
    onModeChanged: field.clear()
    onAccepted: field.list.activate(field.list.currentIndex)
    Keys.onEscapePressed: Panels.close()
    // Before the field's own keys, where Shift+Delete would cut.
    Keys.onPressed: event => {
      const list = field.list;
      const control = event.modifiers & Qt.ControlModifier;
      if (event.key === Qt.Key_Up || control && event.key === Qt.Key_P) list.select(list.currentIndex - 1);
      else if (event.key === Qt.Key_Down || control && event.key === Qt.Key_N) list.select(list.currentIndex + 1);
      else if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) list.select((list.currentIndex + 1) % list.count);
      else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) list.select((list.currentIndex - 1 + list.count) % list.count);
      else if (event.key === Qt.Key_Delete && event.modifiers & Qt.ShiftModifier) list.remove(list.currentIndex);
      else return;
      event.accepted = true;
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      x: field.leftPadding
      text: field.mode.placeholder
      color: Theme.fgDim
      font: field.font
      visible: field.text === ""
    }
  }

  component ResultList: ListView {
    id: list

    required property LauncherMode mode
    property string query: ""
    property int maxRows: 7
    property int rowHeight: 50
    readonly property var results: list.mode.waitsForQuery && list.query === "" ? [] : list.mode.search(list.query)
    readonly property var current: list.results[list.currentIndex] ?? null

    // Keeps the selection where it is while a row goes.
    property bool removing: false

    function select(index: int): void {
      list.currentIndex = Math.max(0, Math.min(list.count - 1, index));
      list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function activate(index: int): void {
      if (index >= 0 && index < list.results.length) list.mode.activated(list.results[index]);
    }

    function remove(index: int): void {
      if (!list.mode.removable || index < 0 || index >= list.results.length) return;
      list.removing = true;
      list.mode.removed(list.results[index]);
      list.removing = false;
    }

    implicitHeight: Math.min(list.count, list.maxRows) * list.rowHeight + Math.max(0, Math.min(list.count, list.maxRows) - 1) * list.spacing
    clip: true
    spacing: 2
    // Only ever jumps, to keep the selected row in view.
    interactive: false
    onCurrentChanged: list.mode.selected = list.current

    model: ScriptModel {
      values: list.results
      objectProp: "key"
      // A new search starts at its best match.
      onValuesChanged: list.select(list.removing ? list.currentIndex : 0)
    }

    // A row per notch, like rofi; touchpad steps add up to a notch.
    WheelHandler {
      property real pending: 0

      target: null
      // The default is mice only.
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: event => {
        pending += event.angleDelta.y;
        const rows = Math.trunc(pending / 120);
        pending -= rows * 120;
        list.select(list.currentIndex - rows);
      }
    }
  }

  component Picture: ClippingRectangle {
    id: picture

    required property var row
    readonly property var size: picture.row.size ?? { width: 1, height: 1 }
    // Shrunk to fit and never enlarged, so a small picture stays sharp and a huge one is decoded small.
    readonly property real ratio: Math.min(1, picture.width / picture.size.width, picture.height / picture.size.height)

    implicitHeight: 38
    implicitWidth: Math.round(picture.implicitHeight * 16 / 9)
    radius: 6
    color: Theme.card

    Image {
      anchors.centerIn: parent
      width: Math.round(picture.size.width * picture.ratio)
      height: Math.round(picture.size.height * picture.ratio)
      sourceSize: Qt.size(width, height)
      source: picture.row.thumbnail ?? ""
      // Pictures can be large; the row shows without waiting for one.
      asynchronous: true
    }
  }

  component ResultRow: Rectangle {
    id: row

    required property var modelData
    required property int index
    required property ResultList list
    readonly property bool current: ListView.isCurrentItem
    readonly property var fields: row.list.mode.fields(row.modelData)

    // Letters in order are marked only where search.js matches them so.
    function loose(text: string): bool {
      return row.fields.some(field => field[1] === text && field[2]);
    }

    width: ListView.view.width
    height: row.list.rowHeight
    radius: 12
    color: row.current ? Theme.selected : area.containsMouse ? Theme.hover : "transparent"

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      onClicked: row.list.activate(row.index)
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: 10
        rightMargin: 14
      }
      spacing: 12

      IconImage {
        visible: !!row.modelData.icon
        source: row.modelData.icon ?? ""
        implicitSize: 32
      }

      Item {
        visible: !!row.modelData.glyph
        implicitWidth: 32
        implicitHeight: 32

        Glyph {
          anchors.centerIn: parent
          path: row.modelData.glyph ?? ""
          size: 24
        }
      }

      Rectangle {
        visible: !!row.modelData.layout
        implicitWidth: 57
        implicitHeight: 32
        radius: 9
        color: Theme.button

        LayoutDiagram {
          anchors.fill: parent
          anchors.margins: 6
          layout: row.modelData.layout ?? []
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Marked {
          Layout.fillWidth: true
          query: row.list.query
          plain: row.modelData.title
          loose: row.loose(row.modelData.title)
          color: Theme.fg
          font: Theme.body
        }

        Marked {
          Layout.fillWidth: true
          visible: plain !== ""
          query: row.list.query
          plain: row.modelData.subtitle ?? ""
          loose: row.loose(row.modelData.subtitle ?? "")
          color: Theme.fgDim
          font: Theme.caption
        }
      }

      Picture {
        visible: !!row.modelData.thumbnail
        row: row.modelData
      }

      // Material Symbols' keyboard_return; a picture already ends its row.
      Glyph {
        visible: row.current && !row.modelData.thumbnail
        path: "m272-440 116 116q11 11 11 28t-11 28q-11 11-28 11t-28-11L148-452q-6-6-8.5-13t-2.5-15q0-8 2.5-15t8.5-13l184-184q11-11 28-11t28 11q11 11 11 28t-11 28L272-520h488v-120q0-17 11.5-28.5T800-680q17 0 28.5 11.5T840-640v120q0 33-23.5 56.5T760-440H272Z"
        size: 18
        color: Theme.fgDim
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Panels.close()
  }

  Timer {
    running: root.height > 0
    interval: 50
    onTriggered: root.settled = true
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    // Always centred, gliding as the matches change its height.
    y: Math.round((root.height - height) / 2)
    width: root.cardWidth
    height: root.fieldHeight + (root.listing ? 1 + root.resultsHeight : 0)
    radius: 22
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline

    Behavior on height {
      enabled: root.settled

      NumberAnimation {
        duration: 200
        easing.type: Easing.OutCubic
      }
    }

    Shadow {}

    // Keeps clicks on the card from closing the launcher.
    MouseArea {
      anchors.fill: parent
    }

    RowLayout {
      id: field

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        leftMargin: 22
        rightMargin: 22
      }
      height: root.fieldHeight
      spacing: 16

      Glyph {
        path: root.mode.glyph
        size: 26
      }

      SearchField {
        id: search

        Layout.fillWidth: true
        list: matches
      }
    }

    Rectangle {
      id: rule

      anchors {
        top: field.bottom
        left: parent.left
        right: parent.right
      }
      height: 1
      color: Theme.border
      visible: root.listing
    }

    // Down to the card's edge as it grows, so the list clips itself inside it.
    RowLayout {
      anchors {
        top: rule.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }
      visible: root.listing
      spacing: 0

      ResultList {
        id: matches

        // 60/40 beside a preview.
        Layout.fillWidth: !root.previewing
        Layout.preferredWidth: root.previewing ? Math.round(root.cardWidth * 0.6) - 16 : -1
        Layout.minimumWidth: Math.max(0, Layout.preferredWidth)
        Layout.fillHeight: true
        Layout.margins: 8
        mode: root.mode
        query: search.text
        maxRows: root.rows

        delegate: ResultRow {
          list: matches
        }
      }

      Rectangle {
        visible: root.previewing
        Layout.fillHeight: true
        implicitWidth: 1
        color: Theme.border
      }

      // Its preview's own width would otherwise move the split with every row.
      Loader {
        visible: root.previewing
        clip: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.margins: 20
        sourceComponent: root.mode.preview
      }
    }
  }
}
