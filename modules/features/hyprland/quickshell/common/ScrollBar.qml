import QtQuick
import QtQuick.Controls.Basic as QQC

QQC.ScrollIndicator {
  id: root

  // Shown while not moving too: a wheel's eased scroll sets contentY itself, which ScrollIndicator never sees as movement.
  property bool held: false

  padding: 0
  contentItem: Rectangle {
    implicitWidth: 4
    implicitHeight: 4
    radius: width / 2
    color: Theme.fgDim
    opacity: (root.active || root.held) && root.size < 1 ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.settle
      }
    }
  }
}
