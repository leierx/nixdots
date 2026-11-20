pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QQC
import QtQuick.Effects
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import qs.common
import qs.osd
import "names.js" as Names

// The control centre's popover under its bar button: GNOME's quick settings.
Overlay {
  id: root

  required property real anchorX
  // The bar's height, which the popover drops below.
  required property real top
  // The most the card may take: what the screen leaves under the bar.
  readonly property real available: height - top - 2 * Theme.gap
  readonly property bool open: Panels.active === name
  property real shown: 0
  // The open menu, held while the card fades out, as Controls shuts it at once.
  property string menu: ""

  Binding on menu {
    when: root.open
    value: Controls.menu
    restoreMode: Binding.RestoreNone
  }

  // What the card stacks, each menu in a slot of its own under the row that opens it, so one eases shut as the next eases open; by id, so an open menu outlives every change around it.
  readonly property var sections: {
    const list = [{ id: "header", kind: "header" }, { id: "levels", kind: "levels" }, { id: "menu:output", kind: "menu", key: "output" }, { id: "menu:input", kind: "menu", key: "input" }];
    for (let i = 0; i < Controls.toggles.length; i += 2) {
      const row = Controls.toggles.slice(i, i + 2);
      list.push({ id: `toggles:${i}`, kind: "toggles", items: row });
      for (const toggle of row) if (toggle.menu) list.push({ id: `menu:${toggle.key}`, kind: "menu", key: toggle.key });
    }
    if (Privacy.kinds.length > 0) list.push({ id: "inuse", kind: "inuse" });
    if (Media.player) list.push({ id: "media", kind: "media" });
    return list;
  }

  signal hidden()

  onOpenChanged: {
    (open ? closing : opening).stop();
    // Closed before it moved, it has nothing to animate, and would never report itself hidden.
    if (!open && shown === 0) Qt.callLater(root.hideClosed);
    else (open ? opening : closing).start();
  }
  onShownChanged: if (shown === 0 && !open) hidden()
  // A window Hyprland has closed stays closed, so the next open needs a new one.
  onClosed: hidden()
  Component.onCompleted: {
    if (open) opening.start();
    else Qt.callLater(root.hideClosed);
  }

  function hideClosed(): void {
    if (!root.open) root.hidden();
  }

  // A track's time as m:ss, or h:mm:ss past an hour.
  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    const pad = n => String(n).padStart(2, "0");
    return s >= 3600 ? `${Math.floor(s / 3600)}:${pad(Math.floor(s % 3600 / 60))}:${pad(s % 60)}` : `${Math.floor(s / 60)}:${pad(s % 60)}`;
  }

  function batteryState(): string {
    if (Power.charging) return Power.remaining > 0 ? `Full in ${Power.duration(Power.remaining)}` : "Charging";
    if (Power.plugged) return "Plugged in";
    return Power.remaining > 0 ? `${Power.duration(Power.remaining)} left` : "On battery";
  }

  // The window of the first app named that has one, by the app's own name or its desktop entry's.
  function windowOf(apps: var): var {
    const toplevels = ToplevelManager.toplevels.values;
    for (const app of apps) {
      const entry = DesktopEntries.heuristicLookup(app);
      const ids = [app, entry?.id ?? "", entry?.startupClass ?? ""].filter(id => id !== "").map(id => id.toLowerCase());
      const found = toplevels.find(toplevel => ids.includes(toplevel.appId.toLowerCase()));
      if (found) return found;
    }
    return null;
  }

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
        return { key: ssid, glyph: Net.signalGlyph(network.signalStrength), title: Net.name(network) || "Hidden network", lock: Net.secured(network), current: network.connected, note: failure || (asking ? Net.askError : "") || state, bad: failure !== "" || asking && Net.askError !== "", asking, action: network.connected && Net.portal ? "Sign in" : "", target: network };
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

  // Kept whole in view in the card too, which scrolls on a short screen.
  function reveal(item: Item): void {
    const top = item.mapToItem(column, 0, 0).y;
    const bottom = top + item.height;
    if (bottom > scroller.contentY + scroller.height) scroller.contentY = Math.min(bottom - scroller.height, scroller.contentHeight - scroller.height);
    if (top < scroller.contentY) scroller.contentY = top;
  }

  card: box
  // While closing, clicks already go to the windows below.
  mask: open ? null : nothing
  WlrLayershell.namespace: "quickshell:controls"
  WlrLayershell.keyboardFocus: open ? root.keyboard : WlrKeyboardFocus.None

  Region {
    id: nothing
  }

  // Not a Behavior: one whose duration follows `open` may start before that duration updates.
  NumberAnimation {
    id: opening

    target: root
    property: "shown"
    to: 1
    duration: Theme.open
    easing.type: Easing.OutQuint
  }

  NumberAnimation {
    id: closing

    target: root
    property: "shown"
    to: 0
    duration: Theme.close
    easing.type: Easing.InCubic
  }

  // A level: its symbol (a mute button where it mutes), the slider, and the arrow to its devices.
  component Level: Row {
    id: level

    property string glyph: ""
    property bool mutes: false
    property bool muted: false
    property real value: 0
    property string opens: ""

    signal moved(real value)
    signal stepped(int notches)
    signal muteClicked()

    spacing: 8

    IconButton {
      id: lead

      anchors.verticalCenter: parent.verticalCenter
      flat: true
      enabled: level.mutes && level.enabled
      checked: level.muted
      glyph: level.glyph
      onClicked: level.muteClicked()
    }

    Slider {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - lead.width - arrow.width - 2 * parent.spacing
      enabled: level.enabled
      value: level.value
      dim: level.muted
      onMoved: value => level.moved(value)
      onStepped: notches => level.stepped(notches)
    }

    IconButton {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      opacity: level.opens !== "" ? 1 : 0
      enabled: level.opens !== ""
      flat: true
      expander: true
      checked: level.opens !== "" && root.menu === level.opens
      pointing: checked ? "down" : "right"
      onClicked: Controls.show(level.opens)
    }
  }

  // GNOME's quick toggle: a pill, its arrow a segment of its own.
  component Pill: Rectangle {
    id: pill

    required property var toggle
    readonly property bool open: root.menu === toggle.key
    property color ink: toggle.on ? Theme.accentFg : Theme.fg
    property color dimInk: toggle.on ? Theme.accentFg : Theme.fgDim
    property color rule: toggle.on ? Theme.accentFg : Theme.border

    height: 48
    radius: height / 2
    opacity: toggle.unavailable ? 0.5 : 1
    color: toggle.on ? Theme.accentBg : Theme.button

    Behavior on color {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    Behavior on ink {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    Behavior on dimInk {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    Behavior on rule {
      ColorAnimation {
        duration: Theme.fade
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.fade
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: main.containsMouse && main.enabled ? Theme.hover : "transparent"

      Behavior on color {
        ColorAnimation {
          duration: Theme.fade
        }
      }
    }

    // A flip's feedback: a ripple spreading from the click, and the symbol's Pop.
    function pop(x: real): void {
      ripple.from = Math.max(0, Math.min(pill.width - pill.height, x - pill.height / 2));
      popping.restart();
    }

    Rectangle {
      id: ripple

      property real from: 0

      height: parent.height
      radius: height / 2
      color: Theme.fg
      opacity: 0
    }

    ParallelAnimation {
      id: popping

      NumberAnimation {
        target: ripple
        property: "x"
        from: ripple.from
        to: 0
        duration: Theme.settle
        easing.type: Easing.OutCubic
      }

      NumberAnimation {
        target: ripple
        property: "width"
        from: pill.height
        to: pill.width
        duration: Theme.settle
        easing.type: Easing.OutCubic
      }

      NumberAnimation {
        target: ripple
        property: "opacity"
        from: 0.25
        to: 0
        duration: Theme.settle
        easing.type: Easing.OutCubic
      }

      Pop {
        target: symbol
      }
    }

    Row {
      x: 14
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - x - (segment.visible ? segment.width : 14)
      spacing: 10

      Glyph {
        id: symbol

        anchors.verticalCenter: parent.verticalCenter
        path: pill.toggle.glyph
        size: 20
        color: pill.ink
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 30

        Text {
          width: parent.width
          text: pill.toggle.title
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: pill.ink
          font: Theme.heading
        }

        Text {
          width: parent.width
          text: pill.toggle.subtitle
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: pill.dimInk
          opacity: pill.toggle.on ? 0.8 : 1

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.fade
            }
          }
          font: Theme.caption
        }
      }
    }

    MouseArea {
      id: main

      objectName: `pill:${pill.toggle.key}`
      width: parent.width - (segment.visible ? segment.width : 0)
      height: parent.height
      hoverEnabled: true
      enabled: !pill.toggle.unavailable
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: mouse => {
        Controls.flip(pill.toggle);
        pill.pop(mouse.x);
      }
    }

    Item {
      id: segment

      anchors.right: parent.right
      visible: pill.toggle.menu
      width: 44
      height: parent.height

      Rectangle {
        width: 1
        height: parent.height - 20
        anchors.verticalCenter: parent.verticalCenter
        color: pill.rule
        opacity: pill.toggle.on ? 0.3 : 1

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.fade
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 1
        topRightRadius: pill.radius
        bottomRightRadius: pill.radius
        color: side.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: Theme.fade
          }
        }
      }

      ExpanderArrow {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -2
        pointing: pill.open ? "down" : "right"
      }

      MouseArea {
        id: side

        objectName: `menu:${pill.toggle.key}`
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Controls.show(pill.toggle.key)
      }
    }
  }

  // An open menu, GNOME's: a header (its symbol in a chip, blue while on, and its title), a filter once the list is long, the list, and what it leads on to.
  component Menu: Rectangle {
    id: menuBox

    required property string key
    // The most it may take; the list scrolls within.
    property real limit: 1e6
    readonly property int rowHeight: 36
    // A row asking for a password: its own row and the field under it.
    readonly property int askingHeight: 2 * rowHeight + 12
    // Wi-Fi's rows are built at most every 150 ms: three hundred networks each changing strength in a scan would otherwise rebuild them three hundred times.
    // Night light's menu is its strength rather than a list.
    readonly property bool tint: key === "night"
    readonly property var all: key === "wifi" ? settled : tint ? [] : root.rows(key)
    property var settled: []
    readonly property real changes: key === "wifi" ? root.touchWifi() : 0
    readonly property bool filtering: all.length > 20
    readonly property var shown: filter.text === "" ? all : all.filter(row => row.asking || row.title.toLowerCase().includes(filter.text.toLowerCase()))
    readonly property string title: ({ wifi: "Wi-Fi", vpn: "VPN", bluetooth: "Bluetooth", output: "Sound Output", input: "Sound Input", night: "Night Light" })[key] ?? key
    readonly property var toggle: Controls.toggles.find(toggle => toggle.key === key) ?? null
    readonly property string glyph: toggle?.glyph ?? (key === "input" ? Microphone.glyph : Volume.glyph)
    readonly property bool on: toggle?.on ?? true
    readonly property var footer: key === "wifi" || key === "vpn" ? ["Network Settings…"] : key === "bluetooth" ? ["Bluetooth Settings…"] : []
    // Said in place of a list with nothing in it.
    readonly property string empty: {
      if (key === "wifi") return !Net.wifiOn ? "Wi-Fi is off" : "Looking for networks…";
      if (key === "bluetooth") return !BluetoothDevices.on ? "Bluetooth is off" : "Looking for devices…";
      if (key === "output") return "No outputs";
      if (key === "input") return "No inputs";
      return "";
    }
    readonly property real chrome: heading.height + (filter.visible ? filter.height + 6 : 0) + (foot.visible ? foot.height + 13 : 0) + 2 * 6

    onChangesChanged: {
      if (settle.running) {
        settle.again = true;
      } else {
        menuBox.settled = root.rows("wifi");
        settle.start();
      }
    }

    function act(name: string): void {
      if (name === "Network Settings…") Net.settings([]);
      else BluetoothDevices.settings();
    }

    // An asking row grows; it is kept whole in view.
    function reveal(item: Item): void {
      const bottom = item.y + item.height;
      if (bottom > list.contentY + list.height) list.contentY = Math.min(bottom - list.height, list.contentHeight - list.height);
      if (item.y < list.contentY) list.contentY = item.y;
      Qt.callLater(root.reveal, item);
    }

    implicitHeight: chrome + (tint ? rowHeight : Math.max(list.contentHeight, rowHeight))
    height: Math.min(implicitHeight, Math.max(chrome + 4 * rowHeight + (all.some(row => row.asking) ? askingHeight : rowHeight), limit))
    radius: Theme.cardRadius
    color: Theme.card

    Timer {
      id: settle

      property bool again: false

      interval: 150
      onTriggered: {
        if (!again) return;
        again = false;
        menuBox.settled = root.rows("wifi");
        restart();
      }
    }

    Column {
      x: 6
      y: 6
      width: parent.width - 12

      Item {
        id: heading

        width: parent.width
        height: 48

        Rectangle {
          id: chip

          x: 4
          anchors.verticalCenter: parent.verticalCenter
          width: 36
          height: 36
          radius: height / 2
          color: menuBox.on ? Theme.accentBg : Theme.button

          Behavior on color {
            ColorAnimation {
              duration: Theme.fade
            }
          }

          Glyph {
            anchors.centerIn: parent
            path: menuBox.glyph
            size: 20
            color: menuBox.on ? Theme.accentFg : Theme.fg
          }
        }

        Text {
          anchors.left: chip.right
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          text: menuBox.title
          color: Theme.fg
          font: Theme.title4
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
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
        height: filter.visible ? 6 : 0
      }

      Item {
        width: parent.width
        height: menuBox.height - menuBox.chrome

        Text {
          x: 40
          height: menuBox.rowHeight
          verticalAlignment: Text.AlignVCenter
          visible: menuBox.shown.length === 0 && !menuBox.tint
          text: menuBox.all.length === 0 ? menuBox.empty : "Nothing matches"
          color: Theme.fgDim
          font: Theme.body
        }

        Slider {
          objectName: "slider:night"
          x: 10
          width: parent.width - 20
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
              duration: Theme.move
              easing.type: Easing.OutCubic
            }
          }

          remove: Transition {
            NumberAnimation {
              property: "opacity"
              to: 0
              duration: Theme.move
              easing.type: Easing.OutCubic
            }
          }

          displaced: Transition {
            NumberAnimation {
              property: "y"
              duration: Theme.move
              easing.type: Easing.OutCubic
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
            radius: Theme.smallRadius
            color: asking ? Theme.hover : "transparent"
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
              acts: !(row.sound && row.modelData.current)
              onClicked: root.choose(menuBox.key, row.modelData)

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
                padding: 12
                visible: (row.modelData.action ?? "") !== ""
                text: row.modelData.action ?? ""
                font: Theme.caption
                onClicked: Net.signIn()
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: (row.modelData.battery ?? -1) >= 0
                text: `${Math.round((row.modelData.battery ?? 0) * 100)} %`
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
                size: 20
                color: row.modelData.link === "connected" ? Theme.accentBg : Theme.fgFaint
              }

              Glyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.current === true && row.modelData.toggle === undefined && row.modelData.tick !== false
                path: Symbols.check
                size: 20
                color: Theme.accentBg
              }

              Switch {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.toggle !== undefined
                checked: row.modelData.toggle ?? false
                scale: 0.85
                onClicked: root.choose(menuBox.key, row.modelData)
              }
            }

            Row {
              visible: row.asking
              x: 10
              y: menuBox.rowHeight + 4
              width: parent.width - 20
              spacing: 8

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
                font: Theme.body
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
        height: foot.visible ? 6 : 0
      }

      Rectangle {
        visible: foot.visible
        width: parent.width
        height: 1
        color: Theme.border
      }

      Item {
        width: 1
        height: foot.visible ? 6 : 0
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

  component Levels: Column {
    spacing: 6

    Row {
      visible: !Volume.present && !Microphone.present
      height: 34
      spacing: 8
      opacity: 0.5

      Item {
        width: 34
        height: 34

        Glyph {
          anchors.centerIn: parent
          path: Symbols.volumeOff
          size: 20
          color: Theme.fg
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Sound not available"
        color: Theme.fg
        font: Theme.body
      }
    }

    Level {
      width: parent.width
      visible: Volume.present
      glyph: Volume.glyph
      mutes: true
      muted: Volume.muted
      value: Volume.volume
      opens: "output"
      onMoved: value => Volume.setVolume(value)
      onStepped: notches => Volume.step(notches)
      onMuteClicked: Volume.toggleMute()
    }

    Level {
      width: parent.width
      visible: Microphone.present
      // A virtual source has nothing to set; it stays in place, so nothing below moves.
      enabled: Microphone.adjustable
      opacity: Microphone.adjustable ? 1 : 0.5
      glyph: Microphone.glyph
      mutes: true
      muted: Microphone.muted
      value: Microphone.volume
      opens: "input"
      onMoved: value => Microphone.setVolume(value)
      onStepped: notches => Microphone.step(notches)
      onMuteClicked: Microphone.toggleMute()
    }

    Repeater {
      model: Object.keys(Brightness.devices)

      Level {
        id: backlight

        required property string modelData
        readonly property var device: Brightness.devices[modelData] ?? null

        width: parent.width
        glyph: Symbols.brightness
        value: device ? device.brightness / device.max : 0
        onMoved: value => Brightness.set(backlight.modelData, value)
        onStepped: notches => Brightness.set(backlight.modelData, Math.round((backlight.value + notches * 0.05) * 20) / 20)
      }
    }
  }

  // GNOME's top row: the battery on the left, then a screenshot, the lock and the power menu.
  component Header: Item {
    id: header

    implicitHeight: 34

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: Power.present
      width: charge.width + 24
      height: 34
      radius: height / 2
      color: Theme.card

      Row {
        id: charge

        anchors.centerIn: parent
        spacing: 8

        BatteryGlyph {
          anchors.verticalCenter: parent.verticalCenter
          level: Power.percent / 100
          charging: Power.charging
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, header.width - actions.width - 56)
          text: `${Power.percent} % · ${root.batteryState()}`
          elide: Text.ElideRight
          color: Theme.fg
          font: Theme.body
        }
      }
    }

    Row {
      id: actions

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      IconButton {
        objectName: "header:screenshot"
        glyph: Symbols.screenshot
        onClicked: Controls.screenshot()
      }

      IconButton {
        objectName: "header:lock"
        glyph: Symbols.lock
        onClicked: Controls.lock()
      }

      IconButton {
        objectName: "header:power"
        glyph: Symbols.power
        onClicked: Controls.powerMenu()
      }
    }
  }

  // GNOME's "In use": a pill per kind of recording, naming the apps; a click raises the first one's window.
  component InUse: Column {
    id: inUse

    spacing: 8

    Text {
      leftPadding: 4
      text: "In Use"
      color: Theme.fgDim
      font: Theme.heading
    }

    Grid {
      columns: 2
      columnSpacing: 12
      rowSpacing: 12

      Repeater {
        model: ScriptModel {
          values: Privacy.kinds
          objectProp: "name"
        }

        Rectangle {
          id: use

          required property var modelData
          readonly property var window: root.windowOf(modelData.apps)
          readonly property var names: modelData.apps.map(app => DesktopEntries.heuristicLookup(app)?.name ?? app)

          width: (inUse.width - 12) / 2
          height: 48
          radius: height / 2
          color: area.containsMouse && area.enabled ? Theme.buttonHover : Theme.button

          Behavior on color {
            ColorAnimation {
              duration: Theme.fade
            }
          }

          Glyph {
            id: chip

            x: 14
            anchors.verticalCenter: parent.verticalCenter
            path: use.modelData.glyph
            size: 20
            color: Theme.inUse
          }

          Column {
            anchors.left: chip.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter

            Text {
              width: parent.width
              text: use.modelData.name === "Screen" ? "Screen Sharing" : use.modelData.name
              elide: Text.ElideRight
              color: Theme.fg
              font: Theme.heading
            }

            Text {
              width: parent.width
              text: use.names.join(", ") || "Through the screen sharing portal"
              textFormat: Text.PlainText
              elide: Text.ElideRight
              color: Theme.fgDim
              font: Theme.caption
            }
          }

          MouseArea {
            id: area

            objectName: `inuse:${use.modelData.name}`
            anchors.fill: parent
            hoverEnabled: true
            enabled: use.window !== null
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              Panels.close();
              use.window?.activate();
            }
          }
        }
      }
    }
  }

  // The player, washed in its album art: the art blurred behind, a big white play.
  component MediaCard: Rectangle {
    id: card

    readonly property bool art: cover.status === Image.Ready
    readonly property bool playing: Media.player?.isPlaying ?? false
    readonly property real length: (Media.player?.lengthSupported ?? false) ? Media.player.length : 0

    implicitHeight: info.implicitHeight + 2 * Theme.padding
    radius: Theme.cardRadius
    color: Theme.card

    Image {
      id: wash

      anchors.fill: parent
      visible: false
      source: cover.source
      sourceSize: Qt.size(96, 96)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      id: shape

      anchors.fill: parent
      visible: false
      radius: parent.radius
      layer.enabled: true
    }

    MultiEffect {
      anchors.fill: parent
      opacity: card.art && wash.status === Image.Ready ? 1 : 0
      source: wash
      autoPaddingEnabled: false
      blurEnabled: true
      blur: 1
      blurMax: 64
      saturation: 0.1
      brightness: -0.4
      maskEnabled: true
      maskSource: shape

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.settle
          easing.type: Easing.OutCubic
        }
      }
    }

    Rectangle {
      id: artwork

      x: Theme.padding
      anchors.verticalCenter: parent.verticalCenter
      width: 84
      height: 84
      radius: Theme.buttonRadius
      color: Theme.button
      clip: true
      // Set down while paused, picked up as it plays.
      scale: card.playing ? 1 : 0.92

      Behavior on scale {
        NumberAnimation {
          duration: Theme.settle
          easing.type: Easing.OutCubic
        }
      }

      Glyph {
        anchors.centerIn: parent
        visible: !card.art
        path: Symbols.music
        size: 36
        color: Theme.fgDim
      }

      Image {
        id: cover

        anchors.fill: parent
        visible: card.art
        source: Media.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(168, 168)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }

    Column {
      id: info

      anchors.left: artwork.right
      anchors.leftMargin: Theme.padding
      anchors.right: parent.right
      anchors.rightMargin: Theme.padding
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        width: parent.width
        text: Media.title
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: Theme.fg
        font: Theme.heading

        MouseArea {
          anchors.fill: parent
          enabled: Media.player?.canRaise ?? false
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            Panels.close();
            Media.player?.raise();
          }
        }
      }

      Text {
        width: parent.width
        visible: text !== ""
        text: Media.artist
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: Theme.fgStrong
        font: Theme.body
      }

      // Dragged or clicked, it seeks where the player can.
      Slider {
        objectName: "slider:media"
        width: parent.width
        visible: card.length > 0
        enabled: Media.player?.canSeek ?? false
        value: card.length > 0 ? (Media.player?.position ?? 0) / card.length : 0
        onMoved: value => {
          if (Media.player) Media.player.position = value * card.length;
        }
        onStepped: notches => {
          if (Media.player) Media.player.position = Math.max(0, Math.min(card.length, Media.player.position + notches * 5));
        }
      }

      Item {
        width: parent.width
        height: 40

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: card.length > 0
          text: root.clock(Media.player?.position ?? 0)
          color: Theme.fgStrong
          font: Theme.caption
        }

        Row {
          anchors.centerIn: parent
          spacing: 6

          IconButton {
            anchors.verticalCenter: parent.verticalCenter
            flat: true
            enabled: Media.player?.canGoPrevious ?? false
            opacity: enabled ? 1 : 0.5
            glyph: Symbols.previous
            onClicked: Media.player?.previous()
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            radius: height / 2
            color: Theme.fg
            opacity: playArea.enabled ? 1 : 0.5
            scale: playArea.pressed ? 0.92 : playArea.containsMouse ? 1.06 : 1

            Behavior on scale {
              NumberAnimation {
                duration: Theme.tap
                easing.type: Easing.OutCubic
              }
            }

            Glyph {
              anchors.centerIn: parent
              path: card.playing ? Symbols.pause : Symbols.play
              size: 24
              color: Theme.bg
            }

            MouseArea {
              id: playArea

              objectName: "media:play"
              anchors.fill: parent
              hoverEnabled: true
              enabled: Media.player?.canTogglePlaying ?? false
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: Media.player?.togglePlaying()
            }
          }

          IconButton {
            anchors.verticalCenter: parent.verticalCenter
            flat: true
            enabled: Media.player?.canGoNext ?? false
            opacity: enabled ? 1 : 0.5
            glyph: Symbols.next
            onClicked: Media.player?.next()
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: card.length > 0
          text: root.clock(card.length)
          color: Theme.fgStrong
          font: Theme.caption
        }
      }
    }
  }

  Card {
    id: box

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: Math.min(Math.round(28 * Theme.em), root.width - 2 * Theme.gap)
    height: Math.min(column.implicitHeight + 2 * Theme.padding, root.available)
    radius: Theme.windowRadius
    focus: true
    opacity: root.shown
    // Grown out of its button.
    transform: Scale {
      origin.x: root.anchorX - box.x
      origin.y: -Theme.gap
      xScale: 0.9 + 0.1 * root.shown
      yScale: 0.9 + 0.1 * root.shown
    }

    Flickable {
      id: scroller

      // In the card's padding rather than over the rows.
      QQC.ScrollIndicator.vertical: ScrollBar {
        parent: box
        x: box.width - width - 3
        y: Theme.padding
        height: scroller.height
        held: true
      }
      anchors.fill: parent
      anchors.margins: Theme.padding
      contentHeight: column.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Column {
        id: column

        // Everything but the menus, which take what is left of the screen; measured a frame later, as a menu's own height feeds back into the column.
        property real fixed: 0

        function measure(): void {
          column.fixed = column.children.filter(child => child.menu === false).reduce((sum, child) => sum + child.height, 0);
        }

        onChildrenChanged: Qt.callLater(column.measure)

        width: scroller.width

        Repeater {
          model: ScriptModel {
            values: root.sections
            objectProp: "id"
          }

          // The gap above each is its own, so a menu eases open from nothing, gap and all.
          Item {
            id: section

            required property var modelData
            readonly property bool menu: modelData.kind === "menu"
            readonly property real gap: modelData.kind === "header" ? 0 : 12
            property real opened: !menu || root.menu === modelData.key ? 1 : 0

            Behavior on opened {
              NumberAnimation {
                duration: Theme.move
                easing.type: Easing.OutCubic
              }
            }

            width: column.width
            height: (gap + (loader.item?.height ?? 0)) * opened
            clip: menu
            onHeightChanged: if (!menu) Qt.callLater(column.measure)
            Component.onCompleted: Qt.callLater(column.measure)

            Loader {
              id: loader

              y: section.gap
              width: parent.width
              active: section.opened > 0
              sourceComponent: ({ header: headerSection, levels: levels, toggles: toggleRow, menu: menuSection, inuse: inUseSection, media: media })[section.modelData.kind]
            }

            Component {
              id: headerSection

              Header {}
            }

            Component {
              id: inUseSection

              InUse {}
            }

            Component {
              id: levels

              Levels {}
            }

            Component {
              id: media

              MediaCard {}
            }

            Component {
              id: menuSection

              Menu {
                key: section.modelData.key
                limit: root.available - 2 * Theme.padding - column.fixed - section.gap
              }
            }

            Component {
              id: toggleRow

              Row {
                spacing: 12

                Repeater {
                  model: ScriptModel {
                    values: section.modelData.items
                    objectProp: "key"
                  }

                  Pill {
                    required property var modelData

                    width: (column.width - 12) / 2
                    toggle: modelData
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
