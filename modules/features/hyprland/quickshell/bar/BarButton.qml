import QtQuick
import qs.common

Button {
  implicitHeight: Theme.barItemHeight
  pill: true
  padding: text === "" ? Theme.basePadding : Theme.padding
  font: Theme.numeric
  colorTime: Theme.panelButtonTime
  color: {
    if (checked || pressed) return hovered ? Theme.panelActiveHoverBg : Theme.panelActiveBg;
    return hovered ? Theme.panelHoverBg : "transparent";
  }
}
