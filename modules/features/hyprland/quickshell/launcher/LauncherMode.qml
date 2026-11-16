import QtQuick
import Quickshell
import qs.common
import "search.js" as Search

Scope {
  id: root

  required property string name
  required property string title
  required property string glyph
  property string placeholder: "Search…"
  property var rows: []
  property bool removable: false
  property bool wide: false
  property bool waitsForQuery: false
  // The list's share of a card with a preview.
  property real split: 0.6
  property var fields: row => [[1.0, row.title, true], [0.8, row.subtitle]]
  property Component preview: null
  property var selected: null

  readonly property bool open: Panels.active === name

  signal opened()
  signal activated(var row)
  signal removed(var row)

  onOpenChanged: {
    if (open) opened();
    else selected = null;
  }

  // A row's boost only reorders matches, so it is added after the filter.
  function search(query: string): var {
    return root.rows
      .map((row, index) => ({ row, index, score: Search.scoreFields(query, root.fields(row)) }))
      .filter(match => match.score >= 0)
      .sort((a, b) => b.score + (b.row.boost ?? 0) - a.score - (a.row.boost ?? 0) || a.index - b.index)
      .map(match => match.row);
  }
}
