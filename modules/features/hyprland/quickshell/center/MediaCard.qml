pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.common
import qs.controls
import qs.nix

// The player that played last, first in the center as GNOME shows media: a message card washed in its album art, a big white play.
Rectangle {
  id: card

  // A track's time as m:ss, or h:mm:ss past an hour.
  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    const pad = n => String(n).padStart(2, "0");
    return s >= 3600 ? `${Math.floor(s / 3600)}:${pad(Math.floor(s % 3600 / 60))}:${pad(s % 60)}` : `${Math.floor(s / 60)}:${pad(s % 60)}`;
  }


  readonly property bool art: cover.status === Image.Ready
  readonly property bool playing: Media.player?.isPlaying ?? false
  readonly property real length: Media.length

  implicitHeight: info.implicitHeight + 2 * Theme.padding
  radius: Theme.messageRadius
  color: Theme.messageBg

  Image {
    id: wash

    anchors.fill: parent
    visible: false
    source: cover.source
    sourceSize: Qt.size(96, 96)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  Rectangle {
    id: shape

    anchors.fill: parent
    visible: false
    radius: parent.radius
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: parent
    opacity: card.art && wash.status === Image.Ready ? 1 : 0
    source: wash
    autoPaddingEnabled: false
    blurEnabled: true
    blur: 1
    blurMax: 64
    // The art's colour kept, as the user asked, and darkened enough to read over.
    saturation: 0.9
    brightness: -0.5
    maskEnabled: true
    maskSource: shape

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.settle
        easing.type: Easing.OutCubic
      }
    }
  }

  Rectangle {
    id: artwork

    x: Theme.padding
    anchors.verticalCenter: parent.verticalCenter
    width: 84
    height: 84
    radius: Theme.baseRadius
    color: Theme.buttonBg
    clip: true
    // Set down while paused, picked up as it plays.
    scale: card.playing ? 1 : 0.92

    Behavior on scale {
      NumberAnimation {
        duration: Theme.settle
        easing.type: Easing.OutCubic
      }
    }

    Glyph {
      anchors.centerIn: parent
      visible: !card.art
      path: Symbols.music
      size: 32
      color: Theme.fgDim
    }

    Image {
      id: cover

      anchors.fill: parent
      visible: card.art
      source: Media.player?.trackArtUrl ?? ""
      sourceSize: Qt.size(168, 168)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
  }

  Column {
    id: info

    anchors.left: artwork.right
    anchors.leftMargin: Theme.padding
    anchors.right: parent.right
    anchors.rightMargin: Theme.padding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: Media.title
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fg
      font: Theme.heading

      MouseArea {
        anchors.fill: parent
        enabled: Media.player?.canRaise ?? false
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          Panels.close();
          Media.player?.raise();
        }
      }
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: Media.artist
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fgStrong
      font: Theme.body
    }

    // Dragged or clicked, it seeks where the player can.
    Slider {
      objectName: "slider:media"
      width: parent.width
      visible: card.length > 0
      enabled: Media.player?.canSeek ?? false
      value: card.length > 0 ? (Media.player?.position ?? 0) / card.length : 0
      onMoved: value => {
        if (Media.player) Media.player.position = value * card.length;
      }
      onStepped: notches => {
        if (Media.player) Media.player.position = Math.max(0, Math.min(card.length, Media.player.position + notches * 5));
      }
    }

    Item {
      width: parent.width
      height: 40

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: card.length > 0
        text: card.clock(Media.player?.position ?? 0)
        color: Theme.fgStrong
        font: Theme.caption
      }

      Row {
        anchors.centerIn: parent
        spacing: 6

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          flat: true
          enabled: Media.player?.canGoPrevious ?? false
          glyph: Symbols.previous
          tooltip: "Previous Track"
          onClicked: Media.player?.previous()
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          height: 40
          radius: height / 2
          color: Theme.fg
          opacity: playArea.enabled ? 1 : 0.5
          activeFocusOnTab: playArea.enabled || activeFocus
          Keys.onReturnPressed: Media.player?.togglePlaying()
          Keys.onSpacePressed: Media.player?.togglePlaying()
          Glyph {
            anchors.centerIn: parent
            path: card.playing ? Symbols.pause : Symbols.play
            size: 16
            color: Theme.panelBg
          }

          MouseArea {
            id: playArea

            objectName: "media:play"
            anchors.fill: parent
            hoverEnabled: true
            enabled: Media.player?.canTogglePlaying ?? false
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Media.player?.togglePlaying()
          }

          TooltipArea {
            text: card.playing ? "Pause" : "Play"
          }

          FocusRing {
            corner: height / 2
            on: parent.activeFocus
          }
        }

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          flat: true
          enabled: Media.player?.canGoNext ?? false
          glyph: Symbols.next
          tooltip: "Next Track"
          onClicked: Media.player?.next()
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: card.length > 0
        text: card.clock(card.length)
        color: Theme.fgStrong
        font: Theme.caption
      }
    }
  }
}
