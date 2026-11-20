pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "names.js" as Names

// The MPRIS player worth a card: the one that started playing last, else one paused.
Singleton {
  id: root

  readonly property var players: Mpris.players.values
  property string last: ""
  readonly property var player: players.find(p => p.dbusName === last && p.isPlaying) ?? players.find(p => p.isPlaying) ?? players.find(p => p.dbusName === last && p.playbackState === MprisPlaybackState.Paused) ?? players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? null
  readonly property string title: Names.clean(player?.trackTitle ?? "") || Names.clean(player?.identity ?? "")
  readonly property string artist: Names.clean(player?.trackArtist ?? "")
  // The card is open: the position moves only when asked.
  property bool watched: false

  onWatchedChanged: if (watched) root.player?.positionChanged()

  Instantiator {
    model: root.players

    Connections {
      required property var modelData

      target: modelData

      function onIsPlayingChanged(): void {
        if (modelData.isPlaying) root.last = modelData.dbusName;
      }
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.watched && (root.player?.isPlaying ?? false)
    // At once as the card opens, so it shows where the track is rather than where it was.
    triggeredOnStart: true
    onTriggered: root.player?.positionChanged()
  }
}
