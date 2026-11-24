import QtQuick
import Quickshell
import qs.common
import "search.js" as Search

Scope {
  id: root

  required property string name
  required property string title
  property string glyph: ""
  property string image: ""
  property string placeholder: "Search…"
  // Said in place of the list while it has nothing and nothing is typed.
  property string nothing: ""
  property var rows: []
  property bool removable: false
  property real split: 0.6
  property var fields: row => [[1.0, row.title, true], [0.8, row.subtitle]]
  property Component preview: null
  property var selected: null
  property var find: null
  // Its rows are still coming: nothing is said in their place yet.
  property bool loading: false

  readonly property bool open: Panels.active === name

  signal opened()
  signal activated(var row)
  signal removed(var row)

  onOpenChanged: {
    if (open) opened();
    else selected = null;
  }

  function fieldsOf(row: var): var {
    return root.fields(row);
  }

  // A row's boost only reorders matches, so it is added after the filter.
  function search(query: string): var {
    if (root.find) return root.find(query);
    const typed = Search.words(query);
    return root.rows
      .map((row, index) => ({ row, index, score: Search.scoreFields(typed, root.fieldsOf(row)) }))
      .filter(match => match.score >= 0)
      .sort((a, b) => b.score + (b.row.boost ?? 0) - a.score - (a.row.boost ?? 0) || a.index - b.index)
      .map(match => match.row);
  }
}
