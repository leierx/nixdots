// Shell's .icon-button: a circle round a 16 px symbol, 36 px as in quick settings, 28 px beside a slider or in a row.
Button {
  property bool small: false

  implicitWidth: implicitHeight
  implicitHeight: small ? 28 : Theme.iconButtonSize
  pill: true
  padding: 0
  glyphSize: 16
}
