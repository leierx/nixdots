pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

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
  // Material Symbols' mic, videocam and screen_share, filled
  readonly property string micGlyph: "M480-400q-50 0-85-35t-35-85v-240q0-50 35-85t85-35q50 0 85 35t35 85v240q0 50-35 85t-85 35Zm-40 240v-83q-92-13-157.5-78T203-479q-2-17 9-29t28-12q17 0 28.5 11.5T284-480q14 70 69.5 115T480-320q72 0 127-45.5T676-480q4-17 15.5-28.5T720-520q17 0 28 12t9 29q-14 91-79 157t-158 79v83q0 17-11.5 28.5T480-120q-17 0-28.5-11.5T440-160Z"
  readonly property string cameraGlyph: "M160-160q-33 0-56.5-23.5T80-240v-480q0-33 23.5-56.5T160-800h480q33 0 56.5 23.5T720-720v180l126-126q10-10 22-5t12 19v344q0 14-12 19t-22-5L720-420v180q0 33-23.5 56.5T640-160H160Z"
  readonly property string screenGlyph: "M440-520h80v56q0 7 6 9.5t11-2.5l89-89q6-6 6-14t-6-14l-89-89q-5-5-11-2.5t-6 9.5v56h-80q-50 0-85 35t-35 85v40q0 17 11.5 28.5T360-400q17 0 28.5-11.5T400-440v-40q0-17 11.5-28.5T440-520ZM80-120q-17 0-28.5-11.5T40-160q0-17 11.5-28.5T80-200h800q17 0 28.5 11.5T920-160q0 17-11.5 28.5T880-120H80Zm80-120q-33 0-56.5-23.5T80-320v-440q0-33 23.5-56.5T160-840h640q33 0 56.5 23.5T880-760v440q0 33-23.5 56.5T800-240H160Z"
  // What records, in the order the bar shows it.
  readonly property var kinds: [
    { name: "Microphone", on: micActive, glyph: micGlyph, apps: mic },
    { name: "Camera", on: cameraActive, glyph: cameraGlyph, apps: camera },
    { name: "Screen", on: screenActive, glyph: screenGlyph, apps: screen }
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
