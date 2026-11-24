Button {
  property bool small: false
  // Inline with a line of text, costing it no height: a notification's close and expander.
  property bool tiny: false

  implicitWidth: implicitHeight
  implicitHeight: tiny ? 24 : small ? 28 : Theme.iconButtonSize
  pill: true
  padding: 0
  glyphSize: 16
}
