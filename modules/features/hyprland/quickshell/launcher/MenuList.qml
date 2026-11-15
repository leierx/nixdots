import QtQuick
import qs.common

// A search field above a list of results, driven by the keyboard. `results`
// is an array of rows, each with a `title`, optionally a `subtitle` and an
// `icon` image source, plus whatever the picker wants handed back when the row
// is picked with `activated(row)`.
//
// The search field holds the keyboard focus. Keys it has no use for, like Up
// and Down, travel up to this item, and Escape on to MenuWindow.
Column {
  id: root

  property alias query: input.text
  property string placeholder: ""
  property var results: []
  // Rows shown before the list starts scrolling.
  property int maxRows: 7
  readonly property int rowHeight: 50

  // The most rows shown since the picker opened, so narrowing a search leaves
  // the card where it is.
  property int peakRows: 0

  // The height at peakRows, for MenuWindow.fullHeight. The column leaves out
  // the spacing while the list is hidden.
  readonly property real fullHeight: input.height + (peakRows > 0 ? spacing : 0) + peakRows * rowHeight

  signal activated(var row)

  // The children take their width from the column, so it needs its own.
  width: parent.width
  spacing: 4

  onResultsChanged: peakRows = Math.max(peakRows, Math.min(results.length, maxRows))
  Component.onCompleted: peakRows = Math.min(results.length, maxRows)

  // Select a row, clamped to the list, and scroll it into view.
  function select(index) {
    list.currentIndex = Math.max(0, Math.min(list.count - 1, index));
    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
  }

  function activate(index) {
    if (index >= 0 && index < results.length) activated(results[index]);
  }

  Keys.onUpPressed: select(list.currentIndex - 1)
  Keys.onDownPressed: select(list.currentIndex + 1)

  TextInput {
    id: input

    width: parent.width
    padding: 12
    focus: true
    color: Theme.fg
    selectionColor: Theme.accentBg
    selectedTextColor: Theme.accentFg
    font: Theme.body
    // The default cursor blinks; this one stays lit.
    cursorDelegate: Rectangle {
      width: 1
      color: Theme.fg
      visible: input.cursorVisible
    }
    onAccepted: root.activate(list.currentIndex)

    Text {
      x: input.leftPadding
      y: input.topPadding
      text: root.placeholder
      color: Theme.fgDim
      font: input.font
      visible: input.text === ""
    }
  }

  ListView {
    id: list

    width: parent.width
    height: Math.min(count, root.maxRows) * root.rowHeight
    visible: count > 0
    clip: true
    model: root.results
    // A new search starts at its best match.
    onModelChanged: root.select(0)
    // No dragging or kinetic scrolling: the list only ever jumps to keep the
    // selected row in view.
    interactive: false

    // The wheel moves the selection a row per notch, like rofi. Touchpads
    // send smaller steps, which add up until they make a whole notch.
    WheelHandler {
      property real pending: 0

      target: null
      // The default is mice only.
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: event => {
        pending += event.angleDelta.y;
        const rows = Math.trunc(pending / 120);
        pending -= rows * 120;
        root.select(list.currentIndex - rows);
      }
    }

    delegate: MenuRow {
      width: list.width
      height: root.rowHeight
      onClicked: root.activate(index)
    }
  }
}
