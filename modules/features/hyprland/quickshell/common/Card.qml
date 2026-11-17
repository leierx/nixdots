import QtQuick

Rectangle {
  radius: Theme.windowRadius
  color: Theme.bg
  border.width: 1
  border.color: Theme.outline

  Keys.onEscapePressed: Panels.close()

  Shadow {}
}
