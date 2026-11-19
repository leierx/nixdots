import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.bar
import qs.center
import qs.common
import qs.notifications
import qs.osd

// qs-test adds this to the session's copy of the shell only: `qst state` is its `state`.
Scope {
  IpcHandler {
    target: "probe"

    function state(): string {
      return JSON.stringify({
        panel: Panels.active,
        screens: Quickshell.screens.map(s => ({
          name: s.name,
          x: s.x,
          y: s.y,
          width: s.width,
          height: s.height,
          monitor: Hyprland.monitors.values.find(m => m.name === s.name)?.id ?? null
        })),
        focused: Hyprland.focusedMonitor?.name ?? null,
        monitors: Hyprland.monitors.values.map(m => ({
          id: m.id,
          name: m.name,
          workspace: m.activeWorkspace?.id ?? null
        })),
        workspaces: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => ({
          id: w.id,
          monitor: w.monitor?.name ?? null,
          // As the bar and the window switcher name it.
          label: WorkspaceOwners.label(w, w.monitor),
          windows: w.toplevels.values.length
        })),
        windows: Hyprland.toplevels.values.map(t => ({
          class: t.lastIpcObject?.class ?? null,
          monitor: t.monitor?.name ?? null,
          workspace: t.workspace?.id ?? null
        })),
        popups: Notifs.popups.map(e => ({
          summary: e.notification?.summary ?? null,
          screen: e.screen,
          hovered: e.hovered,
          waiting: e.waiting
        })),
        notifications: Notifs.entries.length,
        history: Notifs.entries.map(e => ({ app: Notifs.appKey(e), summary: e.notification?.summary ?? null })),
        dnd: Notifs.dnd,
        volume: { percent: Volume.percent, muted: Volume.muted, output: Volume.devices.find(d => d.current)?.name ?? null },
        input: Osd.sourceName,
        osd: Osd.current ? Object.assign({ screen: Osd.screen }, Osd.current) : null,
        osdShown: Osd.serial,
        osdSettling: Osd.settling,
        brightness: Brightness.devices,
        caps: CapsLock.on,
        privacy: { mic: Privacy.mic, screen: Privacy.screenActive ? Privacy.screen : null, camera: Privacy.cameraActive ? Privacy.camera : null },
        keepAwake: KeepAwake.active
      });
    }
  }
}
