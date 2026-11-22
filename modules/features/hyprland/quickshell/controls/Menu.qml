pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import qs.common
import qs.nix
import "devices.js" as Devices
import "names.js" as Names

// An open menu, GNOME's: a header (its symbol in a chip, blue while on, and its title), a filter once the list is long, the list, and what it leads on to.
Rectangle {
  id: menuBox

  // A row that grew, for the panel to keep whole in view as it scrolls.
  signal wantsInView(Item item)

  function rows(key: string): var {
    if (key === "wifi") {
      const rank = network => network.connected || network.stateChanging ? 2 : network.known ? 1 : 0;
      // By the steps the glyph shows, not the strength itself, so a rescan moves a row only when its glyph changes.
      const steps = network => [0.05, 0.25, 0.5, 0.75].filter(step => network.signalStrength > step).length;
      const sorted = [...Net.networks].sort((a, b) => rank(b) - rank(a) || steps(b) - steps(a) || a.name.localeCompare(b.name, undefined, { numeric: true }));
      const list = sorted.map(network => {
        const ssid = network.name;
        const asking = ssid === Net.asking;
        const failure = Net.failures[ssid] ?? "";
        const state = network.state === ConnectionState.Connecting ? "Connecting…" : network.state === ConnectionState.Disconnecting ? "Disconnecting…" : network.connected ? "" : Net.enterprise(network) && !network.known ? "Enterprise" : network.known ? "Saved" : "";
        return { key: ssid, glyph: Net.signalGlyph(network.signalStrength), title: Net.name(network) || "Hidden Network", lock: Net.secured(network), current: network.connected, note: failure || (asking ? Net.askError : "") || state, bad: failure !== "" || asking && Net.askError !== "", asking, action: network.connected && Net.signInOffered ? "Sign In" : "", target: network };
      });
      // Gone while its password is typed: kept, saying so, with what was typed.
      if (Net.asking !== "" && !list.some(row => row.asking)) list.unshift({ key: Net.asking, glyph: Symbols.wifi0, title: Names.clean(Net.asking), lock: true, note: "Out of range", bad: true, asking: true, target: null });
      return list;
    }
    if (key === "vpn") return Net.vpns.map(vpn => {
      const busy = Net.busy(vpn.uuid);
      const asking = Net.vpnAsking === vpn.uuid;
      return { key: vpn.uuid, glyph: Symbols.vpn, title: Names.clean(vpn.name), toggle: vpn.active, note: busy === "up" || vpn.state === "activating" ? "Connecting…" : busy === "down" ? "Disconnecting…" : asking ? Net.vpnError || "Password needed" : "", bad: asking && Net.vpnError !== "", asking, target: vpn };
    });
    if (key === "bluetooth") return BluetoothDevices.devices.map(device => ({ key: device.address, glyph: BluetoothDevices.glyph(device), title: BluetoothDevices.name(device), current: device.connected, tick: false, note: BluetoothDevices.note(device), bad: (BluetoothDevices.failures[device.address] ?? "") !== "", battery: device.connected && device.batteryAvailable ? device.battery : -1, link: device.connected ? "connected" : device.paired ? "paired" : "", target: device }));
    if (key === "sound") {
      const devices = (backend, side, other) => backend.devices.map(device => {
        const kind = Devices.kind(device.props, side === "input", other.hardware.has(device.props?.["device.id"]));
        return { key: `${side}:${device.id}`, side, kind, glyph: Volume.kindGlyph(kind), title: device.name, current: device.current, target: device.index };
      });
      const first = list => [...list.filter(device => device.current), ...list.filter(device => !device.current)];
      const outputs = first(devices(Volume, "output", Microphone));
      const inputs = Microphone.present ? first(devices(Microphone, "input", Volume)) : [];
      const heading = (side, title, gap) => [{ key: `heading:${side}`, heading: true, title, gap }];
      return [...(outputs.length > 0 ? heading("output", "Output", false) : []), ...outputs, ...(inputs.length > 0 ? heading("input", "Input", outputs.length > 0) : []), ...inputs];
    }
    return [];
  }

  function choose(key: string, row: var): void {
    if (key === "wifi") {
      if (row.asking) Net.cancel();
      else if (row.target) Net.choose(row.target);
    } else if (key === "vpn") {
      Net.toggleVpn(row.key);
    } else if (key === "bluetooth") {
      BluetoothDevices.choose(row.target);
    } else if (row.side && !row.current) {
      (row.side === "output" ? Volume : Microphone).choose(row.target);
    }
  }


  required property string key
  // The most it may take; the list scrolls within.
  property real limit: 1e6
  readonly property int rowHeight: Theme.menuRowHeight
  readonly property int headingHeight: 28
  // A row asking for a password: its own row and the field under it.
  readonly property int askingHeight: 2 * rowHeight + 12
  // Night light's menu is its strength rather than a list.
  readonly property bool tint: key === "night"
  readonly property var all: key === "wifi" ? settled : tint ? [] : menuBox.rows(key)
  // Wi-Fi's rows, built every 150 ms while it is open: a binding would rebuild them for each of the hundreds of changes a scan makes.
  property var settled: []
  readonly property int count: all.filter(row => !row.heading).length
  readonly property bool filtering: count > 20
  readonly property var shown: {
    if (filter.text === "") return all;
    const text = filter.text.toLowerCase();
    const kept = all.filter(row => row.asking || row.heading || row.title.toLowerCase().includes(text));
    // A heading only over rows that matched.
    return kept.filter((row, i) => !row.heading || (kept[i + 1] && !kept[i + 1].heading));
  }
  readonly property string title: ({ wifi: "Wi-Fi", vpn: "VPN", bluetooth: "Bluetooth", sound: "Sound", night: "Night Light" })[key] ?? key
  readonly property var toggle: Controls.toggles.find(toggle => toggle.key === key) ?? null
  readonly property string glyph: toggle?.glyph ?? (Volume.present ? Volume.glyph : Symbols.volumeOff)
  readonly property bool on: toggle?.on ?? true
  readonly property var footer: key === "wifi" || key === "vpn" ? ["Network Settings"] : key === "bluetooth" ? ["Bluetooth Settings"] : key === "sound" ? ["Audio Settings"] : []
  // Said in place of a list with nothing in it.
  readonly property string empty: {
    if (key === "wifi") return !Net.wifiOn ? "Wi-Fi is off" : "Looking for networks…";
    if (key === "bluetooth") return !BluetoothDevices.on ? "Bluetooth is off" : "Looking for devices…";
    if (key === "sound") return "No outputs";
    return "";
  }
  readonly property real chrome: heading.height + (filter.visible ? filter.height + Theme.basePadding : 0) + (foot.visible ? foot.height + 2 * Theme.basePadding + 1 : 0) + Theme.padding + Theme.basePadding

  function act(name: string): void {
    if (name === "Network Settings") Net.settings([]);
    else if (name === "Audio Settings") Volume.settings();
    else BluetoothDevices.settings();
  }

  // An asking row grows; it is kept whole in view.
  function reveal(item: Item): void {
    const bottom = item.y + item.height;
    if (bottom > list.contentY + list.height) list.contentY = Math.min(bottom - list.height, list.contentHeight - list.height);
    if (item.y < list.contentY) list.contentY = item.y;
    Qt.callLater(menuBox.wantsInView, item);
  }

  implicitHeight: chrome + (tint ? rowHeight : Math.max(list.contentHeight, rowHeight))
  height: Math.min(implicitHeight, Math.max(chrome + 4 * rowHeight + (all.some(row => row.asking) ? askingHeight : rowHeight), limit))
  radius: Theme.toggleMenuRadius
  color: Theme.cardBg

  Timer {
    interval: 150
    repeat: true
    running: menuBox.key === "wifi"
    triggeredOnStart: true
    onTriggered: menuBox.settled = menuBox.rows("wifi")
  }

  Column {
    x: Theme.basePadding
    y: Theme.padding
    width: parent.width - 2 * Theme.basePadding

    Item {
      id: heading

      width: parent.width
      height: 32 + Theme.padding

      // 16 px in a 32 px disc, the accent while on (ours: Shell's 24 in 42 outweighed the rows in MDI's filled symbols).
      Rectangle {
        id: chip

        x: Theme.basePadding
        width: 32
        height: 32
        radius: height / 2
        color: menuBox.on ? Theme.accentBg : Theme.headerIconBg

        Behavior on color {
          ColorAnimation {
            duration: Theme.quickTime
          }
        }

        Glyph {
          anchors.centerIn: parent
          path: menuBox.glyph
          size: 16
          color: menuBox.on ? Theme.accentFg : Theme.fg
        }
      }

      Text {
        anchors.left: chip.right
        anchors.leftMargin: Theme.padding
        anchors.verticalCenter: chip.verticalCenter
        text: menuBox.title
        color: Theme.fg
        font: Theme.title4
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.padding
        anchors.verticalCenter: chip.verticalCenter
        visible: menuBox.filtering || menuBox.tint
        text: menuBox.tint ? `${NightLight.temperature} K` : `${menuBox.count}`
        color: Theme.fgDim
        font: Theme.caption
      }
    }

    TextField {
      id: filter

      visible: menuBox.filtering
      width: parent.width
      placeholder: "Filter"
    }

    Item {
      width: 1
      height: filter.visible ? Theme.basePadding : 0
    }

    Item {
      width: parent.width
      height: menuBox.height - menuBox.chrome

      EmptyLine {
        x: 16 + Theme.basePadding
        width: parent.width - x
        height: menuBox.rowHeight
        visible: menuBox.shown.length === 0 && !menuBox.tint
        text: menuBox.all.length === 0 ? menuBox.empty : "No results"
      }

      Slider {
        objectName: "slider:night"
        x: Theme.padding
        width: parent.width - 2 * Theme.padding
        height: menuBox.rowHeight
        visible: menuBox.tint
        value: NightLight.strength
        dim: !NightLight.on
        onMoved: value => NightLight.setStrength(value)
        onStepped: notches => NightLight.setStrength(NightLight.strength + notches * 0.05)
      }

      // Only the rows in view exist, so a thousand cost what a dozen do.
      ListView {
        id: list

        anchors.fill: parent
        visible: !menuBox.tint
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        // No current row: one would take the keyboard from a password field as the rows move.
        currentIndex: -1
        keyNavigationEnabled: false
        model: ScriptModel {
          values: menuBox.shown
          objectProp: "key"
        }

        add: Transition {
          NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }
        }

        remove: Transition {
          NumberAnimation {
            property: "opacity"
            to: 0
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }
        }

        displaced: Transition {
          NumberAnimation {
            property: "y"
            duration: Theme.popupTime
            easing.type: Easing.OutQuad
          }
        }

        delegate: Rectangle {
          id: row

          required property var modelData
          readonly property bool asking: modelData.asking ?? false
          readonly property string askAgain: asking ? (modelData.note ?? "") : ""
          readonly property bool sound: menuBox.key === "sound"
          readonly property bool heading: modelData.heading ?? false

          width: ListView.view.width
          height: heading ? menuBox.headingHeight + (modelData.gap ? Theme.basePadding : 0) : asking ? menuBox.askingHeight : menuBox.rowHeight
          radius: Theme.menuItemRadius
          color: asking ? Theme.menuHoverBg : "transparent"
          onHeightChanged: if (asking) Qt.callLater(menuBox.reveal, row)
          onAskingChanged: if (asking) password.input.forceActiveFocus()
          // Asked again after a wrong one, the field takes the keyboard back for the next try.
          onAskAgainChanged: if (asking) password.input.forceActiveFocus()
          Component.onCompleted: if (asking) password.input.forceActiveFocus()

          Text {
            x: Theme.padding
            y: parent.height - height
            height: menuBox.headingHeight
            visible: row.heading
            verticalAlignment: Text.AlignVCenter
            text: row.modelData.title
            color: Theme.fgDim
            font: Theme.captionHeading
          }

          ListRow {
            visible: !row.heading
            width: parent.width
            areaName: `row:${row.modelData.title}`
            glyph: row.modelData.glyph ?? ""
            title: row.modelData.title
            strong: row.modelData.current === true
            // An asking row is filled already; a hover on top would sink its note below 3:1.
            acts: !(row.sound && row.modelData.current) && !row.asking
            onClicked: menuBox.choose(menuBox.key, row.modelData)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, row.width * (row.modelData.bad ? 0.55 : 0.4))
              visible: (row.modelData.note ?? "") !== "" && !signIn.visible
              text: row.modelData.note ?? ""
              textFormat: Text.PlainText
              elide: Text.ElideRight
              color: row.modelData.bad ? Theme.destructive : Theme.fgDim
              font: Theme.caption
            }

            // Something else than the row's own click: the captive portal's sign-in.
            Button {
              id: signIn

              objectName: "sign-in"
              anchors.verticalCenter: parent.verticalCenter
              implicitHeight: 28
              padding: Theme.padding
              pill: true
              visible: (row.modelData.action ?? "") !== ""
              text: row.modelData.action ?? ""
              onClicked: Net.signIn()
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: (row.modelData.battery ?? -1) >= 0
              text: Theme.unit(Math.round((row.modelData.battery ?? 0) * 100), "%")
              color: Theme.fgDim
              font: Theme.caption
            }

            BatteryGlyph {
              anchors.verticalCenter: parent.verticalCenter
              visible: (row.modelData.battery ?? -1) >= 0
              size: 16
              level: row.modelData.battery ?? 0
            }

            Glyph {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.modelData.lock ?? false
              path: Symbols.lock
              size: 16
              color: Theme.fgDim
            }

            Glyph {
              anchors.verticalCenter: parent.verticalCenter
              visible: (row.modelData.link ?? "") !== ""
              path: row.modelData.link === "connected" ? Symbols.bluetoothConnected : Symbols.bluetooth
              size: 16
              color: row.modelData.link === "connected" ? Theme.accentBg : Theme.fgFaint
            }

            Glyph {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.modelData.current === true && row.modelData.toggle === undefined && row.modelData.tick !== false
              path: Symbols.check
              size: 16
              color: Theme.accentBg
            }

            Switch {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.modelData.toggle !== undefined
              checked: row.modelData.toggle ?? false
              onClicked: menuBox.choose(menuBox.key, row.modelData)
            }
          }

          Row {
            visible: row.asking
            x: Theme.padding
            y: menuBox.rowHeight + Theme.baseMargin
            width: parent.width - 2 * Theme.padding
            spacing: Theme.basePadding

            TextField {
              id: password

              width: parent.width - connect.width - parent.spacing
              password: true
              placeholder: "Password"
              onAccepted: if (connect.enabled) connect.clicked(Qt.LeftButton)
            }

            Button {
              id: connect

              implicitHeight: 36
              text: "Connect"
              suggested: true
              enabled: password.text !== "" && (menuBox.key !== "wifi" || row.modelData.target !== null)
              onClicked: {
                if (menuBox.key === "wifi") Net.submit(row.modelData.key, password.text);
                else Net.vpnPassword(row.modelData.key, password.text);
              }
            }
          }
        }
      }
    }

    Item {
      width: 1
      height: foot.visible ? Theme.basePadding : 0
    }

    Rectangle {
      visible: foot.visible
      width: parent.width
      height: 1
      color: Theme.separator
    }

    Item {
      width: 1
      height: foot.visible ? Theme.basePadding : 0
    }

    Column {
      id: foot

      visible: menuBox.footer.length > 0
      width: parent.width

      Repeater {
        model: menuBox.footer

        ListRow {
          required property string modelData

          width: foot.width
          areaName: `action:${modelData}`
          glyph: Symbols.settings
          title: modelData
          onClicked: menuBox.act(modelData)
        }
      }
    }
  }
}
