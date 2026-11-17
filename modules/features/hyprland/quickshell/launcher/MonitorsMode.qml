pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common

LauncherMode {
  id: root

  // Kept between opens, and an equal output changes nothing, so the menu opens whole.
  property string statusText: ""
  property string profilesText: ""
  readonly property var status: {
    try {
      return JSON.parse(root.statusText);
    } catch (error) {
      if (root.statusText !== "") console.warn(`hyprmoncfg status: ${error}`);
      return null;
    }
  }
  // Only for the pictures; a profile that fails to parse goes without one.
  readonly property var profiles: {
    const profiles = {};
    for (const text of root.profilesText.split("\x1e").filter(text => text.trim() !== "")) {
      try {
        const profile = JSON.parse(text);
        profiles[profile.name] = profile.outputs ?? [];
      } catch (error) {
        console.warn(`hyprmoncfg profile: ${error}`);
      }
    }
    return profiles;
  }
  // hyprmoncfg saves no size for an output turned off, and the fullest profile says which side it is on.
  readonly property var reference: {
    const reference = {};
    const enabled = outputs => outputs.filter(output => output.enabled).length;
    for (const outputs of Object.values(root.profiles).sort((a, b) => enabled(b) - enabled(a))) {
      for (const output of outputs) {
        if (output.enabled && root.sized(output) && !(output.key in reference)) reference[output.key] = output;
      }
    }
    return reference;
  }
  // Connector names for the outputs plugged in, which tell two of one model apart.
  readonly property var connectors: {
    const connectors = {};
    for (const monitor of root.status?.monitors ?? []) connectors[monitor.key] = monitor.name;
    return connectors;
  }
  // Hyprland reports each plugged-in output's size in mm.
  readonly property var inches: {
    const inches = {};
    for (const monitor of Hyprland.monitors.values) {
      const ipc = monitor.lastIpcObject;
      if (ipc?.physicalWidth > 0 && ipc?.physicalHeight > 0) inches[monitor.name] = Math.round(Math.hypot(ipc.physicalWidth, ipc.physicalHeight) / 25.4);
    }
    return inches;
  }

  name: "monitors"
  title: "Monitor layouts"
  // Material Symbols' tv_displays
  glyph: "M120-320q-17 0-28.5-11.5T80-360v-440q0-33 23.5-56.5T160-880h520q17 0 28.5 11.5T720-840q0 17-11.5 28.5T680-800H160v440q0 17-11.5 28.5T120-320ZM480-80q-17 0-28.5-11.5T440-120v-40H320q-33 0-56.5-23.5T240-240v-400q0-33 23.5-56.5T320-720h520q33 0 56.5 23.5T920-640v400q0 33-23.5 56.5T840-160H720v40q0 17-11.5 28.5T680-80H480ZM320-240h520v-400H320v400Zm260-200Z"
  placeholder: "Monitor layout…"
  split: 0.5
  preview: Preview {
    row: root.selected
  }
  // The recommended profile is what the daemon applies on the next hotplug, so it leads.
  rows: {
    if (!root.status) return [];
    const recommended = root.status.recommended_profile?.name;
    return (root.status.profiles ?? [])
      .map(profile => ({
        key: profile.name,
        title: profile.name,
        subtitle: [profile.active ? "Active" : "", profile.name === recommended ? "Recommended" : ""].filter(part => part).join(" · "),
        profile: profile.name,
        layout: root.layout(profile.name),
      }))
      .sort((a, b) => (b.profile === recommended) - (a.profile === recommended) || a.title.localeCompare(b.title));
  }

  function sized(output): bool {
    return output.width > 0 && output.height > 0;
  }

  function layout(name: string): var {
    const logical = output => {
      const turned = output.transform % 2 === 1;
      const width = output.width / (output.scale || 1);
      const height = output.height / (output.scale || 1);
      return { width: turned ? height : width, height: turned ? width : height };
    };
    const outputs = (root.profiles[name] ?? [])
      .filter(output => !output.enabled || root.sized(output))
      .map(output => {
        const reference = root.reference[output.key];
        const shape = root.sized(output) ? output : reference;
        const connector = root.connectors[output.key] ?? "";
        return Object.assign({
          key: output.key,
          name: [output.make, output.model].filter(part => part).join(" ") || output.description,
          connector,
          inches: root.inches[connector] ?? 0,
          enabled: output.enabled,
          x: output.enabled ? output.x : null,
          y: output.enabled ? output.y : null,
          reference,
          mode: output.enabled ? `${output.width}×${output.height} @ ${Math.round(output.refresh)} Hz` : "",
          position: `${output.x}x${output.y}`,
          scale: output.scale,
        }, shape ? logical(shape) : { width: 1920, height: 1080 });
      });
    // One turned off goes where the fullest profile has it, shifted so an output on in both lines up.
    const anchor = outputs.find(output => output.enabled && output.reference);
    const dx = anchor ? anchor.x - anchor.reference.x : 0;
    const dy = anchor ? anchor.y - anchor.reference.y : 0;
    const overlaps = (a, b) => a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
    for (const output of outputs.filter(output => !output.enabled && output.reference)) {
      const spot = { x: output.reference.x + dx, y: output.reference.y + dy, width: output.width, height: output.height };
      if (!outputs.some(other => other.enabled && overlaps(spot, other))) Object.assign(output, { x: spot.x, y: spot.y });
    }
    const order = outputs.filter(output => output.enabled).sort((a, b) => a.x - b.x || a.y - b.y);
    return outputs.map(output => Object.assign(output, { number: order.indexOf(output) + 1 }));
  }

  function load(): void {
    statusCommand.running = true;
    profilesCommand.running = true;
  }

  Component.onCompleted: load()
  onOpened: {
    load();
    if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) Hyprland.refreshMonitors();
  }
  onActivated: row => {
    // The launcher is gone by then, so a failure comes back as a notification.
    Quickshell.execDetached(["sh", "-c", 'out=$(hyprmoncfg apply --confirm-timeout 0 "$1" 2>&1) || notify-send -u critical "hyprmoncfg: $1" "$out"', "sh", row.profile]);
    Panels.close();
  }

  component Preview: ColumnLayout {
    id: preview

    required property var row
    readonly property var outputs: [
      ...(row?.layout.filter(output => output.enabled).sort((a, b) => a.number - b.number) ?? []),
      ...(row?.layout.filter(output => !output.enabled) ?? []),
    ]
    // Six lines at most, the last saying how many more.
    readonly property int lines: outputs.length > 6 ? 5 : 6

    spacing: 6

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: preview.row?.title ?? ""
      color: Theme.fg
      font: Theme.title2
      elide: Text.ElideRight
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: preview.row?.subtitle || " "
      color: Theme.fgDim
      font: Theme.heading
      elide: Text.ElideRight
    }

    LayoutDiagram {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 60
      Layout.topMargin: 14
      Layout.bottomMargin: 14
      layout: preview.row?.layout ?? []
      color: Theme.fg
      numbered: true
    }

    Repeater {
      model: preview.outputs.slice(0, preview.lines)

      RowLayout {
        id: output

        required property var modelData

        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: preview.width
        spacing: 10

        // Outlined for one turned off, as the drawing has it.
        Rectangle {
          implicitWidth: Math.max(20, number.implicitWidth + 10)
          implicitHeight: 20
          radius: Theme.smallRadius
          color: output.modelData.enabled ? Theme.fg : "transparent"
          border.width: output.modelData.enabled ? 0 : 1
          border.color: Theme.fgDim

          Text {
            id: number

            anchors.centerIn: parent
            visible: output.modelData.enabled
            text: output.modelData.number
            color: Theme.bg
            font: Theme.captionHeading
          }
        }

        Text {
          visible: text !== ""
          text: output.modelData.connector
          color: output.modelData.enabled ? Theme.fg : Theme.fgDim
          font: Theme.heading
        }

        Text {
          Layout.fillWidth: true
          text: [output.modelData.name, output.modelData.inches > 0 ? `${output.modelData.inches}″` : ""].filter(part => part).join(" · ")
          color: output.modelData.enabled ? Theme.fg : Theme.fgDim
          font: Theme.body
          elide: Text.ElideRight
        }

        // The position tells apart two of one model that are not plugged in.
        Text {
          text: output.modelData.enabled ? [output.modelData.mode, output.modelData.scale !== 1 ? `×${output.modelData.scale}` : "", output.modelData.connector ? "" : `at ${output.modelData.position}`].filter(part => part).join(" · ") : "off"
          color: Theme.fgDim
          font: Theme.body
        }
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      visible: preview.outputs.length > preview.lines
      text: `and ${preview.outputs.length - preview.lines} more`
      color: Theme.fgDim
      font: Theme.body
    }
  }

  Command {
    id: statusCommand

    command: ["hyprmoncfg", "status", "--json"]
    // A refresh that fails, mid-hotplug say, leaves the last status up rather than closing the menu.
    quiet: !root.open || root.status !== null
    onDone: output => root.statusText = output
  }

  Command {
    id: profilesCommand

    name: "hyprmoncfg profiles"
    quiet: !root.open || root.profilesText !== ""
    // Parted by a record separator, which JSON never holds, so a file written over several lines still reads as one.
    command: ["sh", "-c", 'for file in "${XDG_CONFIG_HOME:-$HOME/.config}"/hyprmoncfg/profiles/*.json; do cat "$file"; printf "\\036"; done']
    onDone: output => root.profilesText = output
  }
}
