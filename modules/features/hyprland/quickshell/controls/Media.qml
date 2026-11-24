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
  // The card's: kept while it plays and for a moment after it stops, so a hover preview or an ad elsewhere never takes it.
  property string shown: ""
  // Picked on the card. It holds while its player plays; once that stops, the next player to play takes the card back.
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
  // The art as a local file, a remote one downloaded in the background and cached: ColorQuantizer reads only files, and the card would fetch it again on each open. A track's stays while the next one's downloads.
  property string artFile: ""
  // What the card shows: the local file, or art Qt loads itself (data:) that has none.
  readonly property string artShown: artFile !== "" || /^https?:/.test(art) ? artFile : art
  // The card's colours from its cover (Theme.cover): the last cover's stay while the next is read, none after art without colours.
  property var tint: null

  onWatchedChanged: if (watched) root.player?.positionChanged()
  onPlayerChanged: remember(0)
  onPlayersChanged: choose()
  onArtChanged: cover()
  // Another player's art never stands in for this one's while it downloads.
  onShownChanged: {
    root.artFile = "";
    root.cover();
  }
  onArtFileChanged: {
    if (root.artFile === "") root.tint = null;
    else if (root.artFile === quantizer.read) root.tint = Theme.cover(quantizer.colors);
    else {
      quantizer.asked = root.artFile;
      quantizer.source = root.artFile;
    }
  }
  Component.onCompleted: choose()

  function remember(fallback: real): void {
    root.known = (root.player?.lengthSupported ?? false) && root.player.length > 0 ? root.player.length : fallback;
  }

  function choose(): void {
    const live = root.players.filter(p => p.isPlaying || p.playbackState === MprisPlaybackState.Paused);
    // A player that just stopped is held too, so one stopping between tracks keeps its place.
    const held = name => live.find(p => p.dbusName === name) ?? (hold.running && hold.player === name ? root.players.find(p => p.dbusName === name) ?? null : null);
    if (live.length < 2 || live.length > 3 || !held(root.pinned)) root.pinned = "";
    const current = held(root.shown);
    const playing = live.filter(p => p.isPlaying);
    const next = held(root.pinned) ?? (current?.isPlaying || (current && hold.running) ? current : null) ?? playing.find(p => p.dbusName === root.last) ?? playing[0] ?? current ?? live.find(p => p.dbusName === root.last) ?? live[0] ?? null;
    root.shown = next?.dbusName ?? "";
  }

  // Clicked again, the pin goes and the card follows playback.
  function pin(name: string): void {
    root.pinned = root.pinned === name ? "" : name;
    root.choose();
  }

  function cover(): void {
    const art = root.art;
    if (art.startsWith("file://")) root.artFile = art;
    else if (art.startsWith("/")) root.artFile = `file://${art}`;
    else if (/^https?:\/\//.test(art)) {
      if (!download.running) download.get(art);
    } else root.artFile = "";
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
        if (modelData.isPlaying) {
          root.last = modelData.dbusName;
          const pinned = root.players.find(p => p.dbusName === root.pinned);
          if (pinned && pinned.dbusName !== modelData.dbusName && !pinned.isPlaying) root.pinned = "";
        } else if (modelData.dbusName === root.shown) hold.start(modelData.dbusName);
        root.choose();
      }
    }
  }

  Timer {
    id: hold

    // The shown player that stopped playing.
    property string player: ""

    function start(name: string): void {
      hold.player = name;
      hold.restart();
    }

    interval: 2000
    onTriggered: {
      if (hold.player === root.pinned && !root.players.find(p => p.dbusName === hold.player)?.isPlaying && root.players.some(p => p.isPlaying)) root.pinned = "";
      root.choose();
    }
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
    // Kept by URL, the last 32 used; only a picture is kept (a captive portal answers with a page), written aside and moved in, so ColorQuantizer never reads half a file.
    command: ["sh", "-c", 'f=$1; dir=${f%/*}; if [ -s "$f" ]; then touch "$f"; else type=$(curl --fail --silent --show-error --globoff --location --proto =http,https --proto-redir =http,https --max-time 20 --max-filesize 20000000 --create-dirs --write-out "%{content_type}" --output "$f.part" "$2") && case $type in image/*) mv "$f.part" "$f" ;; *) false ;; esac || { rm -f "$f.part"; echo "not a picture: ${type:-no answer}" >&2; exit 1; }; fi; ls -1t "$dir" | tail -n +33 | while read -r name; do rm -f "$dir/$name"; done', "sh", file, url]
    onDone: {
      if (download.url === root.art) root.artFile = `file://${download.file}`;
      else root.cover();
    }
    onFailed: {
      if (download.url === root.art) root.artFile = "";
      else root.cover();
    }
  }

  ColorQuantizer {
    id: quantizer

    // The file the colours are of, and the one asked for: a new source drops the run for the last.
    property string read: ""
    property string asked: ""

    depth: 3
    rescaleSize: 64
    onColorsChanged: {
      quantizer.read = quantizer.asked;
      if (quantizer.read === root.artFile) root.tint = Theme.cover(quantizer.colors);
    }
  }

  // Held as the card's cover asks for it, so the card has it decoded the moment it opens.
  Image {
    visible: false
    source: root.artShown
    sourceSize: Qt.size(168, 168)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
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
