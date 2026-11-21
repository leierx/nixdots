import QtQuick
import qs.common

// Shell's .panel-button: a bold pill inset 3 px, filled only under the pointer or while what it opens is open.
Button {
  implicitHeight: Theme.barItemHeight
  pill: true
  padding: text === "" ? Theme.basePadding : Theme.padding
  font: Theme.numericHeading
  color: {
    if (checked || pressed) return hovered ? Theme.panelActiveHoverBg : Theme.panelActiveBg;
    return hovered ? Theme.panelHoverBg : "transparent";
  }
}
