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
  // When each player last started playing, by bus name.
  property var started: ({})
  // The card's: the last player to start, once it has played a moment (a hover preview never takes it); kept for a moment after it stops, then back to the one before.
  property string shown: ""
  // Picked on the card. It holds while its player plays; once that has stopped, it goes as another plays.
  property string pinned: ""
  property real pinnedAt: 0
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
    const now = Date.now();
    const live = root.players.filter(p => p.isPlaying || p.playbackState === MprisPlaybackState.Paused);
    const since = p => root.started[p.dbusName] ?? 0;
    // A player that just stopped is held too, so one stopping between tracks keeps its place.
    const held = name => live.find(p => p.dbusName === name) ?? (hold.running && hold.player === name ? root.players.find(p => p.dbusName === name) ?? null : null);
    const playing = live.filter(p => p.isPlaying);
    const settled = playing.filter(p => now - since(p) >= settle.wait);
    const newest = list => list.reduce((best, p) => !best || since(p) > since(best) ? p : best, null);
    const pinned = held(root.pinned);
    if (live.length < 2 || live.length > 3 || !pinned || (!pinned.isPlaying && !(hold.running && hold.player === root.pinned) && settled.some(p => p !== pinned && since(p) > root.pinnedAt))) root.pinned = "";
    const current = held(root.shown);
    const next = held(root.pinned) ?? (current && !current.isPlaying && hold.running && hold.player === root.shown ? current : null) ?? newest(current?.isPlaying ? settled.concat(current) : settled) ?? current ?? newest(playing) ?? live[0] ?? null;
    root.shown = next?.dbusName ?? "";
    const waiting = playing.filter(p => p !== next && now - since(p) < settle.wait);
    if (waiting.length > 0) {
      settle.interval = Math.max(1, settle.wait - Math.max(...waiting.map(p => now - since(p))));
      settle.restart();
    }
  }

  // Clicked again, the pin goes and the card follows playback.
  function pin(name: string): void {
    root.pinned = root.pinned === name ? "" : name;
    root.pinnedAt = Date.now();
    root.choose();
  }

  // The wheel on the card: the next or previous of two or three, pinned as a click on its button would.
  function cycle(by: int): void {
    if (!root.switchable || by === 0) return;
    const at = root.live.findIndex(p => p.dbusName === root.shown);
    const next = root.live[((at + by) % root.live.length + root.live.length) % root.live.length];
    root.pinned = next.dbusName;
    root.pinnedAt = Date.now();
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
      Component.onCompleted: {
        if (!modelData.isPlaying) return;
        root.started[modelData.dbusName] = Date.now();
        root.choose();
      }

      function onPlaybackStateChanged(): void {
        if (modelData.isPlaying) root.started[modelData.dbusName] = Date.now();
        else if (modelData.dbusName === root.shown) hold.start(modelData.dbusName);
        root.choose();
      }
    }
  }

  // How long a player plays before it takes the card, so a YouTube hover preview never does.
  Timer {
    id: settle

    readonly property int wait: 1500

    interval: wait
    onTriggered: root.choose()
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
