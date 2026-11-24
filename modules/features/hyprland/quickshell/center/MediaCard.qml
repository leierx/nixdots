pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common
import qs.controls
import qs.nix

Rectangle {
  id: card

  // A track's time as m:ss, or h:mm:ss past an hour.
  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    const pad = n => String(n).padStart(2, "0");
    return s >= 3600 ? `${Math.floor(s / 3600)}:${pad(Math.floor(s % 3600 / 60))}:${pad(s % 60)}` : `${Math.floor(s / 60)}:${pad(s % 60)}`;
  }

  // A line cut short slides to its end and back while the pointer is on the card.
  component Marquee: Item {
    id: line

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    readonly property real overflow: Math.max(0, label.implicitWidth - width)
    readonly property bool rolling: hover.hovered && overflow > 0

    implicitHeight: label.implicitHeight
    clip: true

    Text {
      id: label

      width: line.rolling ? implicitWidth : line.width
      textFormat: Text.PlainText
      elide: line.rolling ? Text.ElideNone : Text.ElideRight
    }

    SequentialAnimation {
      running: line.rolling
      loops: Animation.Infinite
      onRunningChanged: if (!running) label.x = 0

      PauseAnimation {
        duration: Theme.settle * 2
      }

      NumberAnimation {
        target: label
        property: "x"
        to: -line.overflow
        duration: line.overflow * 30
        easing.type: Easing.InOutSine
      }

      PauseAnimation {
        duration: Theme.settle * 3
      }

      NumberAnimation {
        target: label
        property: "x"
        to: 0
        duration: line.overflow * 30
        easing.type: Easing.InOutSine
      }
    }
  }


  readonly property bool art: cover.status === Image.Ready
  // The art's own shape from square to 16:9, a video's thumbnail (YouTube) whole; taller art is cropped square.
  readonly property real aspect: art && cover.implicitHeight > 0 ? Math.max(1, Math.min(16 / 9, cover.implicitWidth / cover.implicitHeight)) : 1
  // The last art that loaded, kept up while the next track's loads, so a skip never blinks.
  property url shownArt: ""
  readonly property bool playing: Media.player?.isPlaying ?? false
  readonly property real length: Media.length

  implicitHeight: info.implicitHeight + 2 * Theme.padding
  radius: Theme.messageRadius
  color: Media.tint?.card ?? Theme.messageBg

  Behavior on color {
    ColorAnimation {
      duration: Theme.settle
      easing.type: Easing.OutCubic
    }
  }

  HoverHandler {
    id: hover
  }

  // Under the rest, so the seek bar's wheel still seeks; with one player the wheel scrolls the list.
  MouseArea {
    objectName: "media:wheel"
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    cursorShape: undefined
    onWheel: event => {
      if (!Media.switchable) {
        event.accepted = false;
        return;
      }
      Media.cycle(-notches.steps(event));
    }

    WheelSteps {
      id: notches
    }
  }

  Image {
    id: coming

    visible: false
    source: Media.artShown
    sourceSize: Qt.size(168, 168)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    onStatusChanged: if (status !== Image.Loading) card.shownArt = status === Image.Ready ? source : ""
  }

  Rectangle {
    id: artwork

    objectName: "media:art"
    x: Theme.padding
    anchors.verticalCenter: parent.verticalCenter
    width: Math.round(84 * card.aspect)
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
      source: card.shownArt
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

    Marquee {
      id: title

      objectName: "media:title"
      width: parent.width - (switcher.visible ? switcher.width + Theme.basePadding : 0)
      text: Media.title
      color: Theme.fg
      font: Theme.heading
      activeFocusOnTab: (Media.player?.canRaise ?? false) || activeFocus
      Keys.onReturnPressed: title.raise()
      Keys.onSpacePressed: title.raise()

      function raise(): void {
        Panels.close();
        Media.player?.raise();
      }

      FocusRing {
        corner: Theme.baseRadius
        on: parent.activeFocus
      }

      MouseArea {
        anchors.fill: parent
        enabled: Media.player?.canRaise ?? false
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: title.raise()
      }
    }

    Marquee {
      objectName: "media:artist"
      width: parent.width
      visible: text !== ""
      text: Media.artist
      color: Theme.fgStrong
      font: Theme.body
    }

    // Dragged or clicked, it seeks where the player can.
    Slider {
      objectName: "slider:media"
      width: parent.width
      fill: !Media.tint ? Theme.accentBg : Media.tint.accent || Theme.fg
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
          color: playArea.pressed ? Media.tint?.accentPressed || Theme.switchKnob : playArea.containsMouse ? Media.tint?.accentHover || Theme.sliderKnob : Media.tint?.accent || Theme.fg
          opacity: playArea.enabled ? 1 : 0.5

          Behavior on color {
            ColorAnimation {
              duration: Theme.quickTime
              easing.type: Easing.OutQuad
            }
          }
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

  // Two or three players: one button each, in the order they came; a click shows that one and pins it there.
  Row {
    id: switcher

    anchors.right: parent.right
    anchors.rightMargin: Theme.padding
    y: info.y + title.y + (title.height - height) / 2
    spacing: Theme.baseMargin
    visible: Media.switchable

    Repeater {
      model: ScriptModel {
        values: Media.switchable ? Media.live : []
      }

      IconButton {
        id: choice

        required property var modelData
        readonly property string icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.desktopEntry || modelData.identity)?.icon ?? "", true)

        objectName: `media:player:${modelData.identity || modelData.dbusName}`
        tiny: true
        checked: modelData.dbusName === Media.shown
        glyph: icon === "" ? Symbols.music : ""
        tooltip: modelData.identity || modelData.dbusName
        onClicked: Media.pin(modelData.dbusName)

        Image {
          anchors.centerIn: parent
          width: 16
          height: 16
          visible: choice.icon !== ""
          source: choice.icon
          sourceSize: Qt.size(16, 16)
          asynchronous: true
        }
      }
    }
  }
}
