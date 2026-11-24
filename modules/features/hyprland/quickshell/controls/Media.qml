pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.common
import "names.js" as Names

Singleton {
  id: root

  readonly property var players: Mpris.players.values
  // Playing or paused, in the order they came, so the card's buttons never trade places.
  readonly property var live: players.filter(p => p.isPlaying || p.playbackState === MprisPlaybackState.Paused)
  // A button per player on the card for two or three; past that, the sticky choice alone.
  readonly property bool switchable: live.length >= 2 && live.length <= 3
  // The last to start playing.
  property string last: ""
  // The card's: kept while it plays and for a moment after it pauses, so a hover preview or an ad elsewhere never takes it.
  property string shown: ""
  // Picked on the card, held while there is a choice and it is in it.
  property string pinned: ""
  readonly property var player: players.find(p => p.dbusName === root.shown) ?? null
  readonly property string title: Names.clean(player?.trackTitle ?? "") || Names.clean(player?.identity ?? "")
  readonly property string artist: Names.clean(player?.trackArtist ?? "")
  // The track's length as last sent: Firefox drops it from a new track's metadata while it plays, until a pause sends it again.
  property real known: 0
  readonly property real length: (player?.lengthSupported ?? false) && player.length > 0 ? player.length : known
  // The card is open: the position moves only when asked.
  property bool watched: false

  readonly property string art: player?.trackArtUrl ?? ""
  // A local copy of the art, as ColorQuantizer reads only files; the last one stays while the next downloads.
  property string coverFile: ""
  // The card's colours from its cover (Theme.cover), null without one.
  readonly property var tint: coverFile !== "" ? Theme.cover(quantizer.colors) : null

  onWatchedChanged: if (watched) root.player?.positionChanged()
  onPlayerChanged: remember(0)
  onPlayersChanged: choose()
  onArtChanged: cover()
  Component.onCompleted: choose()

  function remember(fallback: real): void {
    root.known = (root.player?.lengthSupported ?? false) && root.player.length > 0 ? root.player.length : fallback;
  }

  function choose(): void {
    const live = root.players.filter(p => p.isPlaying || p.playbackState === MprisPlaybackState.Paused);
    const named = name => live.find(p => p.dbusName === name) ?? null;
    if (live.length > 3 || !named(root.pinned)) root.pinned = "";
    const current = named(root.shown);
    const playing = live.filter(p => p.isPlaying);
    const next = named(root.pinned) ?? (current?.isPlaying || (current && hold.running) ? current : null) ?? playing.find(p => p.dbusName === root.last) ?? playing[0] ?? current ?? named(root.last) ?? live[0] ?? null;
    root.shown = next?.dbusName ?? "";
  }

  // Clicked again, the pin goes and the card follows playback.
  function pin(name: string): void {
    root.pinned = root.pinned === name ? "" : name;
    root.choose();
  }

  function cover(): void {
    if (root.art.startsWith("file://")) root.coverFile = root.art;
    else if (/^https?:\/\//.test(root.art)) {
      if (!download.running) download.get(root.art);
    } else root.coverFile = "";
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

  // A ScriptModel, so a player coming or going leaves the others' watch alone.
  Instantiator {
    model: ScriptModel {
      values: root.players
    }

    Connections {
      required property var modelData

      target: modelData
      // One that arrives already playing is the last to have started.
      Component.onCompleted: if (modelData.isPlaying) root.last = modelData.dbusName

      function onPlaybackStateChanged(): void {
        if (modelData.isPlaying) root.last = modelData.dbusName;
        else if (modelData.dbusName === root.shown) hold.restart();
        root.choose();
      }
    }
  }

  Timer {
    id: hold

    interval: 2000
    onTriggered: root.choose()
  }

  Command {
    id: download

    property string url: ""
    property string file: ""

    function get(url: string): void {
      download.url = url;
      download.file = Quickshell.cachePath(`covers/${Qt.md5(url)}`);
      download.running = true;
    }

    name: "Cover art"
    quiet: true
    // Written aside and moved in, so ColorQuantizer never reads half a file; the others go.
    command: ["sh", "-c", "curl --fail --silent --show-error --location --max-time 20 --create-dirs --output \"$1.part\" \"$2\" && mv \"$1.part\" \"$1\" && find \"${1%/*}\" -type f ! -name \"${1##*/}\" -delete", "sh", file, url]
    onDone: {
      if (download.url === root.art) root.coverFile = `file://${download.file}`;
      else root.cover();
    }
    onFailed: {
      if (download.url === root.art) root.coverFile = "";
      else root.cover();
    }
  }

  ColorQuantizer {
    id: quantizer

    source: root.coverFile
    depth: 3
    rescaleSize: 64
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
