import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.nix

LauncherMode {
  id: root

  name: "windows"
  title: "Windows"
  glyph: Symbols.windows
  placeholder: "Search windows…"
  nothing: "No windows open"
  fields: row => [[1.0, row.title, true], [0.8, row.app, true], [0.4, row.where]]
  preview: Preview {
    row: root.selected
  }
  // Only while open: titles and focus change all day.
  rows: {
    if (!root.open) return [];
    const windows = ToplevelManager.toplevels.values.map((toplevel, index) => {
      const hyprland = Hyprland.toplevels.values.find(other => other.wayland === toplevel) ?? null;
      const entry = DesktopEntries.heuristicLookup(toplevel.appId);
      const app = entry?.name || toplevel.appId;
      const where = root.where(hyprland);
      return {
        // Unique per window, and the same while it lives.
        key: String(toplevel),
        title: toplevel.title || app,
        subtitle: [app, where].filter(part => part).join(" · "),
        app,
        where,
        icon: Quickshell.iconPath(entry?.icon ?? toplevel.appId, "application-x-executable"),
        toplevel,
        hyprland,
        recency: hyprland?.lastIpcObject?.focusHistoryID ?? index,
      };
    });
    // The focused window last, since switching is to another.
    return windows.sort((a, b) => a.toplevel.activated - b.toplevel.activated || a.recency - b.recency);
  }

  function where(hyprland): string {
    const workspace = hyprland?.workspace;
    if (!workspace) return "";
    return [hyprland.monitor?.name, WorkspaceOwners.label(workspace, hyprland.monitor)].filter(part => part).join(" · ");
  }

  // Focus history only comes with a full refresh.
  onOpened: if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) Hyprland.refreshToplevels()
  onActivated: row => {
    if (row.hyprland?.address) {
      const address = row.hyprland.address.startsWith("0x") ? row.hyprland.address : `0x${row.hyprland.address}`;
      Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`);
    } else {
      row.toplevel.activate();
    }
    Panels.close();
  }

  component Preview: ColumnLayout {
    id: preview

    required property var row

    spacing: 10

    Item {
      id: frame

      // Hyprland knows the window's size before its first frame arrives, so the frame keeps its shape as the selection moves.
      readonly property var known: preview.row?.hyprland?.lastIpcObject?.size ?? null
      readonly property var size: {
        if (known?.[0] > 0 && known?.[1] > 0) return Qt.size(known[0], known[1]);
        return capture.hasContent ? capture.sourceSize : null;
      }
      // A tile squeezed below nothing (Hyprland past a few dozen on a workspace) exports a buffer Wayland rejects, which kills the shell.
      readonly property bool capturable: known === null || (known[0] > 0 && known[1] > 0)
      readonly property real ratio: frame.size ? Math.min(frame.width / frame.size.width, frame.height / frame.size.height) : 0

      Layout.fillWidth: true
      Layout.fillHeight: true

      ClippingRectangle {
        id: shape

        anchors.centerIn: parent
        width: frame.size ? Math.round(frame.size.width * frame.ratio) : parent.width
        height: frame.size ? Math.round(frame.size.height * frame.ratio) : parent.height
        radius: Theme.cardRadius
        color: Theme.card

        // Drawn at up to twice the size shown and mipmapped, so a large window shrinks smoothly instead of aliasing.
        ScreencopyView {
          id: capture

          readonly property real density: 2 * Screen.devicePixelRatio

          anchors.fill: parent
          captureSource: frame.capturable ? preview.row?.toplevel ?? null : null
          live: true
          layer.enabled: capture.hasContent
          layer.mipmap: true
          layer.smooth: true
          layer.textureSize: Qt.size(Math.min(capture.sourceSize.width, Math.round(capture.width * capture.density)), Math.min(capture.sourceSize.height, Math.round(capture.height * capture.density)))
        }

        // Quickshell captures a window only through Hyprland's toplevel export.
        IconImage {
          anchors.centerIn: parent
          visible: !capture.hasContent && preview.row !== null
          source: preview.row?.icon ?? ""
          implicitSize: 96
        }
      }

      // A dark window on the dark card has no edge of its own, and a terminal with only a prompt reads as nothing.
      Rectangle {
        anchors.fill: shape
        radius: shape.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.border
      }
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: preview.row?.title ?? ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fg
      font: Theme.heading
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: preview.row?.subtitle ?? ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.fgDim
      font: Theme.caption
    }
  }
}
