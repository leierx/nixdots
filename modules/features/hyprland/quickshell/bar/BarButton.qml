import QtQuick
import qs.common

// Shell's .panel-button: a pill inset 3 px, filled only under the pointer or while what it opens is open; regular weight (ours: Shell's bold read heavy).
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
