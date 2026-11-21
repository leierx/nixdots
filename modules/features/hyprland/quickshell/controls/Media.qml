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
  // The track's length as last sent: Firefox drops it from a new track's metadata while it plays, until a pause sends it again.
  property real known: 0
  readonly property real length: (player?.lengthSupported ?? false) && player.length > 0 ? player.length : known
  // The card is open: the position moves only when asked.
  property bool watched: false

  onWatchedChanged: if (watched) root.player?.positionChanged()
  onPlayerChanged: remember(0)

  function remember(fallback: real): void {
    root.known = (root.player?.lengthSupported ?? false) && root.player.length > 0 ? root.player.length : fallback;
  }

  Connections {
    target: root.player

    function onLengthChanged(): void {
      root.remember(root.known);
    }

    function onPostTrackChanged(): void {
      root.remember(0);
    }
  }

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
