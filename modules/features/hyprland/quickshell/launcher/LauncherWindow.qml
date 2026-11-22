pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.nix
import "search.js" as Search

Overlay {
  id: root

  required property LauncherMode mode
  readonly property bool previewing: mode.preview !== null
  readonly property bool divided: previewing && matches.count > 0

  // Clear of the screen's edges, whatever its size and scale.
  readonly property int margin: Math.round(3 * Theme.em)
  readonly property real cardWidth: Math.min(Math.round((previewing ? 68 : 48) * Theme.em), width - 2 * margin)
  readonly property int fieldHeight: 36 + 2 * Theme.padding
  readonly property int rows: Math.max(1, Math.min(8, Math.floor((height - 2 * margin - fieldHeight - 17) / (matches.rowHeight + matches.spacing))))
  readonly property int resultsHeight: rows * matches.rowHeight + (rows - 1) * matches.spacing + (previewing ? 16 : 8)

  name: mode.name
  card: box

  WlrLayershell.namespace: "quickshell:launcher"

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
    font: Theme.body
    // The default cursor blinks; this one stays lit.
    cursorDelegate: Rectangle {
      width: 1
      color: field.color
      visible: field.cursorVisible
    }

    // Another mode's shortcut while open starts it afresh.
    onModeChanged: field.clear()
    onAccepted: {
      field.list.settle();
      field.list.activate(field.list.currentIndex);
    }
    // Before the field's own keys, where Shift+Delete would cut.
    Keys.onPressed: event => {
      const list = field.list;
      const control = event.modifiers & Qt.ControlModifier;
      const shift = event.modifiers & Qt.ShiftModifier;
      const back = event.key === Qt.Key_Up || control && event.key === Qt.Key_P || event.key === Qt.Key_Backtab || shift && event.key === Qt.Key_Tab;
      const forward = event.key === Qt.Key_Down || control && event.key === Qt.Key_N || event.key === Qt.Key_Tab;
      const half = Math.max(1, Math.floor(list.page / 2));
      const paging = event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown || control && (event.key === Qt.Key_U || event.key === Qt.Key_D);
      if (!back && !forward && !paging && !(shift && event.key === Qt.Key_Delete)) return;
      list.settle();
      if (back) list.step(-1);
      else if (forward) list.step(1);
      else if (event.key === Qt.Key_PageUp) list.select(list.currentIndex - list.page);
      else if (event.key === Qt.Key_PageDown) list.select(list.currentIndex + list.page);
      else if (control && event.key === Qt.Key_U) list.select(list.currentIndex - half);
      else if (control && event.key === Qt.Key_D) list.select(list.currentIndex + half);
      else if (event.key === Qt.Key_Delete && shift) list.removeAt(list.currentIndex);
      else return;
      event.accepted = true;
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      x: field.leftPadding
      text: field.mode.placeholder
      color: Theme.placeholder
      font: field.font
      visible: field.text === ""
    }
  }

  component ResultList: ListView {
    id: list

    required property LauncherMode mode
    property string typed: ""
    property string query: ""
    property int rowHeight: 50
    readonly property var results: list.mode.search(list.query)
    readonly property var current: list.results[list.currentIndex] ?? null
    readonly property int page: Math.max(1, Math.floor((list.height + list.spacing) / (list.rowHeight + list.spacing)))

    // Keeps the selection where it is while a row goes.
    property bool removing: false

    // A long list searches a frame after the key, so the letter shows before a slow search; keys that act on the matches catch up first.
    function settle(): void {
      settling.stop();
      list.query = list.typed;
    }

    onTypedChanged: list.mode.find && list.typed !== "" ? settling.restart() : list.settle()

    function select(index: int): void {
      list.currentIndex = Math.max(0, Math.min(list.count - 1, index));
      list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    // Keys go round; the wheel stops at the ends.
    function step(delta: int): void {
      if (list.count > 0) list.select((list.currentIndex + delta + list.count) % list.count);
    }

    function activate(index: int): void {
      if (index >= 0 && index < list.results.length) list.mode.activated(list.results[index]);
    }

    function removeAt(index: int): void {
      if (!list.mode.removable || index < 0 || index >= list.results.length) return;
      list.removing = true;
      list.mode.removed(list.results[index]);
      list.removing = false;
    }

    clip: true
    spacing: 2
    // Only ever jumps, to keep the selected row in view.
    interactive: false
    onCurrentChanged: list.mode.selected = list.current

    Timer {
      id: settling

      interval: 16
      onTriggered: list.settle()
    }

    model: ScriptModel {
      values: list.results
      objectProp: "key"
      // A new search starts at its best match.
      onValuesChanged: list.select(list.removing ? list.currentIndex : 0)
    }

    // One hover for the list rather than each row's: it holds across the gaps between rows and a pointer leaving for a moment.
    property int hovered: -1

    // From the scene: a handler declared in a ListView belongs to its content, whose coordinates scroll.
    function updateHover(): void {
      const at = list.contentItem.mapFromItem(null, hover.point.scenePosition.x, hover.point.scenePosition.y);
      const index = list.indexAt(at.x, at.y);
      if (index >= 0) list.hovered = index;
    }

    onContentYChanged: if (hover.hovered) list.updateHover()

    HoverHandler {
      id: hover

      onPointChanged: list.updateHover()
    }

    Timer {
      running: !hover.hovered
      interval: 150
      onTriggered: list.hovered = -1
    }

    EmptyState {
      width: list.width
      height: list.height
      visible: list.count === 0
      text: list.query.trim() !== "" ? "No Results" : list.mode.nothing
    }

    WheelSteps {
      id: notches
    }

    // A row per notch, like rofi.
    WheelHandler {
      target: null
      // The default is mice only.
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: event => list.select(list.currentIndex - notches.steps(event))
    }
  }

  component Picture: ClippingRectangle {
    id: picture

    required property var entry
    readonly property var size: picture.entry.size ?? { width: 1, height: 1 }
    // Shrunk to fit and never enlarged, so a small picture stays sharp and a huge one is decoded small.
    readonly property real ratio: Math.min(1, picture.width / picture.size.width, picture.height / picture.size.height)

    implicitHeight: 38
    implicitWidth: Math.round(picture.implicitHeight * 16 / 9)
    radius: Theme.baseRadius
    color: Theme.buttonBg

    Image {
      anchors.centerIn: parent
      width: Math.round(picture.size.width * picture.ratio)
      height: Math.round(picture.size.height * picture.ratio)
      sourceSize: Qt.size(width, height)
      source: picture.entry.thumbnail ?? ""
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
    readonly property var fields: row.list.mode.fieldsOf(row.modelData)

    // Letters in order are marked only where search.js matches them so.
    function loose(text: string): bool {
      return row.fields.some(field => field[1] === text && field[2]);
    }

    width: ListView.view.width
    height: row.list.rowHeight
    // Shell's .list-search-result.
    radius: Theme.tileRadius
    color: row.current ? Theme.selectedBg : row.index === row.list.hovered ? Theme.menuHoverBg : "transparent"

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
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
          size: 32
        }
      }

      Rectangle {
        visible: !!row.modelData.layout
        implicitWidth: 57
        implicitHeight: 32
        radius: Theme.baseRadius
        color: Theme.buttonBg

        LayoutDiagram {
          anchors.fill: parent
          anchors.margins: 6
          limit: 4
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
        entry: row.modelData
      }

      Glyph {
        visible: row.current && !row.modelData.thumbnail
        path: Symbols.keyboardReturn
        size: 16
        color: Theme.fgDim
      }
    }
  }

  Card {
    id: box

    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((root.height - height) / 2)
    width: root.cardWidth
    // Full height from the start, so it holds still while typing.
    height: root.fieldHeight + rule.height + root.resultsHeight

    // Shell's search entry: a pill led by the mode's symbol, ringed while it has the keyboard.
    Rectangle {
      id: field

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Theme.padding
      }
      height: root.fieldHeight - 2 * Theme.padding
      radius: height / 2
      color: Theme.buttonBg
      border.width: search.activeFocus ? 2 : 0
      border.color: Theme.focusRing

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: Theme.padding
        spacing: Theme.basePadding

        Glyph {
          visible: root.mode.image === ""
          path: root.mode.glyph
          size: 16
          color: Theme.fgDim
        }

        Image {
          visible: root.mode.image !== ""
          source: root.mode.image
          sourceSize: Qt.size(16, 16)
        }

        SearchField {
          id: search

          Layout.fillWidth: true
          list: matches
        }
      }
    }

    Rectangle {
      id: rule

      anchors {
        top: field.bottom
        topMargin: Theme.padding
        left: parent.left
        right: parent.right
        leftMargin: Theme.padding
        rightMargin: Theme.padding
      }
      height: root.previewing ? 1 : 0
      color: Theme.separator
      visible: root.previewing
    }

    RowLayout {
      anchors {
        top: rule.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }
      spacing: 0

      ResultList {
        id: matches

        Layout.fillWidth: !root.divided
        Layout.preferredWidth: root.divided ? Math.round(root.cardWidth * root.mode.split) - 16 : -1
        Layout.minimumWidth: Math.max(0, Layout.preferredWidth)
        Layout.fillHeight: true
        Layout.margins: 8
        // Without a line across, the field's own padding already parts it from the rows.
        Layout.topMargin: root.previewing ? 8 : 0
        mode: root.mode
        typed: search.text

        delegate: ResultRow {
          list: matches
        }
      }

      Rectangle {
        visible: root.divided
        Layout.fillHeight: true
        Layout.topMargin: Theme.padding
        Layout.bottomMargin: Theme.padding
        implicitWidth: 1
        color: Theme.separator
      }

      // Its preview's own width would otherwise move the split with every row.
      Loader {
        visible: root.divided
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
