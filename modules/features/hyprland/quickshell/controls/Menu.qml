pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import qs.common
import qs.nix
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
        return { key: ssid, glyph: Net.signalGlyph(network.signalStrength), title: Net.name(network) || "Hidden Network", lock: Net.secured(network), current: network.connected, note: failure || (asking ? Net.askError : "") || state, bad: failure !== "" || asking && Net.askError !== "", asking, action: network.connected && Net.portal ? "Sign In" : "", target: network };
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
    const backend = key === "output" ? Volume : Microphone;
    const devices = backend.devices.map(device => ({ key: `${device.index}`, glyph: "", title: device.name, current: device.current, target: device.index }));
    return [...devices.filter(device => device.current), ...devices.filter(device => !device.current)];
  }

  // Reads what Wi-Fi's rows are built from, cheaply, so any change to it is noticed without building them.
  function touchWifi(): real {
    let seen = Net.asking.length + Net.askError.length + Object.keys(Net.failures).length + (Net.portal ? 1 : 0) + (Net.wifiOn ? 1 : 0);
    for (const network of Net.networks) seen += network.name.length + network.signalStrength + network.state + network.security + (network.known ? 1 : 0) + (network.connected ? 1 : 0);
    // Never the same twice, so even a change that adds up to the same sum is noticed.
    return seen + Math.random();
  }

  function choose(key: string, row: var): void {
    if (key === "wifi") {
      if (row.asking) Net.cancel();
      else if (row.target) Net.choose(row.target);
    } else if (key === "vpn") {
      Net.toggleVpn(row.key);
    } else if (key === "bluetooth") {
      BluetoothDevices.choose(row.target);
    } else if (!row.current) {
      (key === "output" ? Volume : Microphone).choose(row.target);
    }
  }


  required property string key
  // The most it may take; the list scrolls within.
  property real limit: 1e6
  readonly property int rowHeight: Theme.menuRowHeight
  // A row asking for a password: its own row and the field under it.
  readonly property int askingHeight: 2 * rowHeight + 12
  // Wi-Fi's rows are built at most every 150 ms: three hundred networks each changing strength in a scan would otherwise rebuild them three hundred times.
  // Night light's menu is its strength rather than a list.
  readonly property bool tint: key === "night"
  readonly property var all: key === "wifi" ? settled : tint ? [] : menuBox.rows(key)
  property var settled: []
  readonly property real changes: key === "wifi" ? menuBox.touchWifi() : 0
  readonly property bool filtering: all.length > 20
  readonly property var shown: filter.text === "" ? all : all.filter(row => row.asking || row.title.toLowerCase().includes(filter.text.toLowerCase()))
  readonly property string title: ({ wifi: "Wi-Fi", vpn: "VPN", bluetooth: "Bluetooth", output: "Sound Output", input: "Sound Input", night: "Night Light" })[key] ?? key
  readonly property var toggle: Controls.toggles.find(toggle => toggle.key === key) ?? null
  readonly property string glyph: toggle?.glyph ?? (key === "input" ? Microphone.glyph : Volume.glyph)
  readonly property bool on: toggle?.on ?? true
  readonly property var footer: key === "wifi" || key === "vpn" ? ["Network Settings"] : key === "bluetooth" ? ["Bluetooth Settings"] : []
  // Said in place of a list with nothing in it.
  readonly property string empty: {
    if (key === "wifi") return !Net.wifiOn ? "Wi-Fi is off" : "Looking for networks…";
    if (key === "bluetooth") return !BluetoothDevices.on ? "Bluetooth is off" : "Looking for devices…";
    if (key === "output") return "No outputs";
    if (key === "input") return "No inputs";
    return "";
  }
  readonly property real chrome: heading.height + (filter.visible ? filter.height + Theme.basePadding : 0) + (foot.visible ? foot.height + 2 * Theme.basePadding + 1 : 0) + Theme.padding + Theme.basePadding

  onChangesChanged: {
    if (settle.running) {
      settle.again = true;
    } else {
      menuBox.settled = menuBox.rows("wifi");
      settle.start();
    }
  }

  function act(name: string): void {
    if (name === "Network Settings") Net.settings([]);
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
    id: settle

    property bool again: false

    interval: 150
    onTriggered: {
      if (!again) return;
      again = false;
      menuBox.settled = menuBox.rows("wifi");
      restart();
    }
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
        text: menuBox.tint ? `${NightLight.temperature} K` : `${menuBox.all.length}`
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
          readonly property bool sound: menuBox.key === "output" || menuBox.key === "input"

          width: ListView.view.width
          height: asking ? menuBox.askingHeight : menuBox.rowHeight
          radius: Theme.menuItemRadius
          color: asking ? Theme.menuHoverBg : "transparent"
          onHeightChanged: if (asking) Qt.callLater(menuBox.reveal, row)
          onAskingChanged: if (asking) password.input.forceActiveFocus()
          // Asked again after a wrong one, the field takes the keyboard back for the next try.
          onAskAgainChanged: if (asking) password.input.forceActiveFocus()
          Component.onCompleted: if (asking) password.input.forceActiveFocus()

          ListRow {
            width: parent.width
            areaName: `row:${row.modelData.title}`
            glyph: row.modelData.glyph
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
