import QtQuick
import Quickshell
import qs.common

Column {
  id: root

  property alias query: input.text
  property string placeholder: ""
  // Each row needs a unique `key`, by which its delegate is kept as the results change.
  property var results: []
  property int maxRows: 7
  readonly property int rowHeight: 50

  // The most rows shown since the picker opened, so narrowing a search leaves the card where it is.
  property int peakRows: 0

  // The column leaves out the spacing while the list is hidden.
  readonly property real fullHeight: input.height + (peakRows > 0 ? spacing : 0) + peakRows * rowHeight

  signal activated(var row)
  signal removed(var row)

  // Keeps the selection where it is while a row goes.
  property bool removing: false

  // The children take their width from the column, so it needs its own.
  width: parent.width
  spacing: 4

  onResultsChanged: peakRows = Math.max(peakRows, Math.min(results.length, maxRows))
  Component.onCompleted: peakRows = Math.min(results.length, maxRows)

  function select(index) {
    list.currentIndex = Math.max(0, Math.min(list.count - 1, index));
    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
  }

  function activate(index) {
    if (index >= 0 && index < results.length) activated(results[index]);
  }

  function remove(index) {
    if (index < 0 || index >= results.length) return;
    removing = true;
    removed(results[index]);
    removing = false;
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
    // Before the field's own Shift+Delete, which cuts.
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Delete && event.modifiers & Qt.ShiftModifier) {
        root.remove(list.currentIndex);
        event.accepted = true;
      }
    }

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
    model: ScriptModel {
      values: root.results
      objectProp: "key"
      // A new search starts at its best match.
      onValuesChanged: root.select(root.removing ? list.currentIndex : 0)
    }
    // Only ever jumps, to keep the selected row in view.
    interactive: false

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
