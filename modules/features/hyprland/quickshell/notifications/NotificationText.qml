import QtQuick
import qs.common

Text {
  id: root

  signal linkOpened()

  textFormat: Text.StyledText
  color: Theme.fg
  linkColor: Theme.accentBg
  wrapMode: Text.Wrap
  elide: Text.ElideRight
  font: Theme.body
  onLinkActivated: link => {
    Notifs.openUrl(link);
    root.linkOpened();
  }

  HoverHandler {
    cursorShape: root.hoveredLink ? Qt.PointingHandCursor : undefined
  }
}
