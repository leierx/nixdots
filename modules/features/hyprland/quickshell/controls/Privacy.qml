pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.common

// Who is recording: a microphone through PipeWire, the screen through the portal's PipeWire
// streams, and a camera through PipeWire or straight from /dev (camera-users).
Singleton {
  id: root

  // Pavucontrol's and GNOME's level meters capture with peak detection, which PipeWire marks.
  readonly property var meters: ["org.PulseAudio.pavucontrol", "org.gnome.VolumeControl", "org.kde.kmixd"]

  readonly property var links: Pipewire.linkGroups.values
  // Links into capture streams and out of video sources; their state only arrives while tracked.
  readonly property var watchedLinks: links.filter(link => link.source && link.target && (link.target.type === PwNodeType.AudioInStream || link.source.type === PwNodeType.VideoSource))
  readonly property var captures: watchedLinks.filter(link => link.state === PwLinkState.Active && link.target.type === PwNodeType.AudioInStream)
  // A capture stream fed by a microphone while audio flows: a sink's monitor is no microphone,
  // and a filter waiting passively on one records nothing.
  readonly property var micStreams: unique(captures.filter(link => microphone(link.source)).map(link => link.target))
  readonly property var videoSources: Pipewire.nodes.values.filter(node => node.type === PwNodeType.VideoSource)
  // The portal's screen casts are video sources a program makes; a camera is a device's.
  readonly property var screenSources: videoSources.filter(node => node.name.startsWith("xdph-streaming-") || node.ready && !node.properties["device.api"])
  readonly property var cameraSources: videoSources.filter(node => node.ready && !!node.properties["device.api"])
  readonly property var screenViewers: unique(watchedLinks.filter(link => screenSources.includes(link.source)).map(link => link.target))
  readonly property var cameraViewers: unique(watchedLinks.filter(link => link.state === PwLinkState.Active && cameraSources.includes(link.source)).map(link => link.target))

  // camera-users' report: [{ pid, device, name }]. PipeWire's own hold is its clients', named above.
  property var holders: []
  readonly property var cameraHolders: holders.filter(holder => !["pipewire", "wireplumber"].includes(holder.name))
  // Opening a camera to list what it can do is no recording, so a hold counts once it lasts.
  property bool held: false

  readonly property var mic: unique(micStreams.filter(node => node.ready && !meter(node)).map(appName))
  readonly property var screen: screenSources.length > 0 ? unique(screenViewers.filter(node => node.ready).map(appName)) : []
  readonly property bool screenActive: screenSources.length > 0
  readonly property var camera: unique([...cameraViewers.filter(node => node.ready).map(appName), ...(held ? cameraHolders.map(holder => holder.name) : [])])
  readonly property bool cameraActive: cameraViewers.length > 0 || held && cameraHolders.length > 0
  readonly property bool micActive: mic.length > 0
  // What records, in the order the bar shows it.
  readonly property var kinds: [
    { name: "Microphone", on: micActive, glyph: Symbols.mic, apps: mic },
    { name: "Camera", on: cameraActive, glyph: Symbols.camera, apps: camera },
    { name: "Screen", on: screenActive, glyph: Symbols.screenShare, apps: screen }
  ].filter(kind => kind.on)

  function unique(values: var): var {
    return values.filter((value, i) => values.indexOf(value) === i);
  }

  // Quickshell types only the plain classes; a virtual source (a filter's, say) is told by its class.
  function microphone(node: PwNode): bool {
    return node.type === PwNodeType.AudioSource || node.type === PwNodeType.AudioDuplex || node.ready && /^Audio\/(Source|Duplex)/.test(node.properties["media.class"] ?? "");
  }

  function meter(node: PwNode): bool {
    const props = node.properties;
    return props["stream.monitor"] === "true" || props["node.passive"] === "true" || meters.includes(props["application.id"]);
  }

  function appName(node: PwNode): string {
    const props = node.properties;
    return props["application.name"] || props["application.process.binary"] || node.description || node.name;
  }

  onCameraHoldersChanged: {
    if (cameraHolders.length === 0) {
      held = false;
      lasting.stop();
    } else if (!held && !lasting.running) {
      lasting.start();
    }
  }

  // Names and the device behind a source only arrive while something tracks them.
  PwObjectTracker {
    objects: [...root.watchedLinks, ...root.unique([...root.captures.map(link => link.source), ...root.captures.map(link => link.target)]), ...root.videoSources, ...root.screenViewers, ...root.cameraViewers]
  }

  Timer {
    id: lasting

    interval: 500
    onTriggered: root.held = root.cameraHolders.length > 0
  }

  Process {
    id: watcher

    property int failures: 0

    running: true
    command: ["camera-users"]
    stdout: SplitParser {
      onRead: line => {
        watcher.failures = 0;
        try {
          root.holders = JSON.parse(line);
        } catch (error) {
          console.warn(`camera-users: ${error}`);
        }
      }
    }
    onRunningChanged: {
      if (running) return;
      root.holders = [];
      restart.interval = Math.min(5000 * 2 ** failures, 300000);
      failures++;
      console.warn(`camera-users stopped, starting it again in ${restart.interval / 1000} s`);
      restart.start();
    }
  }

  Timer {
    id: restart

    onTriggered: watcher.running = true
  }
}
