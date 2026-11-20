pragma ComponentBehavior: Bound

import QtQuick
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
  // Material Symbols' check
  readonly property string check: "m382-354 339-339q12-12 28-12t28 12q12 12 12 28.5T777-636L410-268q-12 12-28 12t-28-12L182-440q-12-12-11.5-28.5T183-497q12-12 28.5-12t28.5 12l142 143Z"
  // The most the card may take: what the screen leaves under the bar.
  readonly property real available: height - top - 2 * Theme.gap

  // What the card stacks, a menu right under the row that opened it; by id, so an open menu outlives every change around it.
  readonly property var sections: {
    const list = [{ id: "levels", kind: "levels" }];
    if (Controls.menu === "output" || Controls.menu === "input") list.push({ id: `menu:${Controls.menu}`, kind: "menu", key: Controls.menu });
    for (let i = 0; i < Controls.toggles.length; i += 2) {
      const row = Controls.toggles.slice(i, i + 2);
      list.push({ id: `toggles:${i}`, kind: "toggles", items: row });
      if (row.some(toggle => toggle.key === Controls.menu && toggle.menu)) list.push({ id: `menu:${Controls.menu}`, kind: "menu", key: Controls.menu });
    }
    if (Media.player) list.push({ id: "media", kind: "media" });
    return list;
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
        const state = network.state === ConnectionState.Connecting ? "Connecting…" : network.state === ConnectionState.Disconnecting ? "Disconnecting…" : network.connected ? "Connected" : Net.enterprise(network) && !network.known ? "Enterprise" : network.known ? "Saved" : "";
        return { key: ssid, glyph: Net.signalGlyph(network.signalStrength), title: Net.name(network) || "Hidden network", lock: Net.secured(network), current: network.connected, tick: false, note: failure || (asking ? Net.askError : "") || state, bad: failure !== "" || asking && Net.askError !== "", asking, action: network.connected && Net.portal ? "Sign in" : "", target: network };
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
    if (key === "bluetooth") return BluetoothDevices.devices.map(device => ({ key: device.address, glyph: BluetoothDevices.glyph(device), title: BluetoothDevices.name(device), current: device.connected, note: BluetoothDevices.note(device), bad: (BluetoothDevices.failures[device.address] ?? "") !== "", target: device }));
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
  WlrLayershell.namespace: "quickshell:controls"

  component Slider: Item {
    id: slider

    property real value: 0
    property bool dim: false

    signal moved(real value)
    signal stepped(int notches)

    implicitHeight: 26

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: height / 2
      color: Theme.trough

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, slider.value))
        height: parent.height
        radius: parent.radius
        color: slider.dim ? Theme.fgDim : Theme.accentBg
      }
    }

    Rectangle {
      x: Math.max(0, Math.min(1, slider.value)) * (slider.width - width)
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      radius: height / 2
      color: Theme.slider
      scale: drag.pressed ? 1.1 : 1

      Behavior on scale {
        NumberAnimation {
          duration: 100
        }
      }
    }

    MouseArea {
      id: drag

      anchors.fill: parent
      // Set from the slider, which reads its own; a disabled ancestor leaves it reading true.
      enabled: slider.enabled
      cursorShape: !enabled ? Qt.ArrowCursor : pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
      onPressed: mouse => slider.moved(Math.max(0, Math.min(1, mouse.x / width)))
      onPositionChanged: mouse => {
        if (pressed) slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
      }
      onWheel: event => {
        const steps = notches.steps(event);
        if (steps !== 0) slider.stepped(steps);
      }
    }

    WheelSteps {
      id: notches
    }
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

    Button {
      id: lead

      anchors.verticalCenter: parent.verticalCenter
      radius: height / 2
      padding: 0
      flat: !level.mutes
      enabled: level.mutes && level.enabled
      checked: level.muted
      glyph: level.glyph
      glyphSize: 20
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

    Button {
      id: arrow

      anchors.verticalCenter: parent.verticalCenter
      opacity: level.opens !== "" ? 1 : 0
      enabled: level.opens !== ""
      radius: height / 2
      padding: 0
      flat: true
      checked: level.opens !== "" && Controls.menu === level.opens
      onClicked: Controls.show(level.opens)

      Item {
        anchors.centerIn: parent
        width: 16
        height: 16
        rotation: arrow.checked ? 0 : -90

        ExpanderArrow {}
      }
    }
  }

  // GNOME's quick toggle: a pill, its arrow a segment of its own.
  component Pill: Rectangle {
    id: pill

    required property var toggle
    readonly property bool open: Controls.menu === toggle.key

    height: 52
    radius: height / 2
    opacity: toggle.unavailable ? 0.5 : 1
    color: toggle.on ? Theme.accentBg : Theme.button

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: main.containsMouse && main.enabled ? Theme.hover : "transparent"
    }

    Row {
      x: 14
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - x - (segment.visible ? segment.width : 14)
      spacing: 10

      Glyph {
        anchors.verticalCenter: parent.verticalCenter
        path: pill.toggle.glyph
        size: 20
        color: pill.toggle.on ? Theme.accentFg : Theme.fg
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 30

        Text {
          width: parent.width
          text: pill.toggle.title
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: pill.toggle.on ? Theme.accentFg : Theme.fg
          font: Theme.heading
        }

        Text {
          width: parent.width
          text: pill.toggle.subtitle
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: pill.toggle.on ? Theme.accentFg : Theme.fgDim
          opacity: pill.toggle.on ? 0.8 : 1
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
      onClicked: Controls.flip(pill.toggle)
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
        color: pill.toggle.on ? Theme.accentFg : Theme.border
        opacity: pill.toggle.on ? 0.3 : 1
      }

      Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 1
        topRightRadius: pill.radius
        bottomRightRadius: pill.radius
        color: side.containsMouse ? Theme.hover : "transparent"
      }

      Item {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -2
        width: 16
        height: 16
        rotation: pill.open ? 0 : -90

        ExpanderArrow {}
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

  // An open menu: its title, a filter once the list is long, the list, and what it leads on to.
  component Menu: Rectangle {
    id: menuBox

    required property string key
    // The most it may take; the list scrolls within.
    property real limit: 1e6
    // Wi-Fi's rows are built at most every 150 ms: three hundred networks each changing strength in a scan would otherwise rebuild them three hundred times.
    readonly property var all: key === "wifi" ? settled : root.rows(key)
    property var settled: []
    readonly property real changes: key === "wifi" ? root.touchWifi() : 0
    readonly property bool filtering: all.length > 20
    readonly property var shown: filter.text === "" ? all : all.filter(row => row.asking || row.title.toLowerCase().includes(filter.text.toLowerCase()))
    readonly property string title: ({ wifi: "Wi-Fi", vpn: "VPN", bluetooth: "Bluetooth", output: "Sound Output", input: "Sound Input" })[key] ?? key
    readonly property var footer: key === "wifi" ? ["Hidden Network…", "Network Settings…"] : key === "vpn" ? ["Network Settings…"] : key === "bluetooth" ? ["Bluetooth Settings…"] : []
    // Said in place of a list with nothing in it.
    readonly property string empty: {
      if (key === "wifi") return !Net.wifiOn ? "Wi-Fi is off" : "Looking for networks…";
      if (key === "bluetooth") return !BluetoothDevices.on ? "Bluetooth is off" : "Looking for devices…";
      if (key === "output") return "No outputs";
      if (key === "input") return "No inputs";
      return "";
    }
    readonly property real chrome: heading.height + (filterBox.visible ? filterBox.height + 6 : 0) + (foot.visible ? foot.height + 7 : 0) + 2 * 6 + 6

    onChangesChanged: {
      if (settle.running) {
        settle.again = true;
      } else {
        menuBox.settled = root.rows("wifi");
        settle.start();
      }
    }

    function act(name: string): void {
      if (name === "Hidden Network…") Net.settings(["--create", "--type=802-11-wireless"]);
      else if (name === "Network Settings…") Net.settings([]);
      else BluetoothDevices.settings();
    }

    // An asking row grows; it is kept whole in view.
    function reveal(item: Item): void {
      const bottom = item.y + item.height;
      if (bottom > list.contentY + list.height) list.contentY = Math.min(bottom - list.height, list.contentHeight - list.height);
      if (item.y < list.contentY) list.contentY = item.y;
      Qt.callLater(root.reveal, item);
    }

    implicitHeight: chrome + Math.max(list.contentHeight, 32)
    height: Math.min(implicitHeight, Math.max(chrome + 4 * 32 + (all.some(row => row.asking) ? 76 : 32), limit))
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

      Row {
        id: heading

        height: 40
        spacing: 10
        leftPadding: 6

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: menuBox.title
          color: Theme.fg
          font: Theme.title4
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: menuBox.filtering
          text: `${menuBox.all.length}`
          color: Theme.fgDim
          font: Theme.caption
        }
      }

      Rectangle {
        id: filterBox

        visible: menuBox.filtering
        width: parent.width
        height: visible ? 32 : 0
        radius: Theme.smallRadius
        color: Theme.button
        border.width: filter.activeFocus ? 2 : 0
        border.color: Theme.accentBg

        TextInput {
          id: filter

          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          color: Theme.fg
          font: Theme.body
          clip: true
        }

        Text {
          anchors.fill: filter
          verticalAlignment: Text.AlignVCenter
          visible: filter.text === ""
          text: "Filter"
          color: Theme.fgDim
          font: Theme.body
        }
      }

      Item {
        width: 1
        height: filterBox.visible ? 6 : 0
      }

      Item {
        width: parent.width
        height: menuBox.height - menuBox.chrome

        Text {
          x: 10
          height: 32
          verticalAlignment: Text.AlignVCenter
          visible: menuBox.shown.length === 0
          text: menuBox.all.length === 0 ? menuBox.empty : "Nothing matches"
          color: Theme.fgDim
          font: Theme.body
        }

        // Only the rows in view exist, so a thousand cost what a dozen do.
        ListView {
          id: list

          anchors.fill: parent
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

          delegate: Rectangle {
            id: row

            required property var modelData
            readonly property bool asking: modelData.asking ?? false
            readonly property string askAgain: asking ? (modelData.note ?? "") : ""

            width: ListView.view.width
            height: asking ? 76 : 32
            radius: Theme.smallRadius
            color: rowArea.containsMouse || asking ? Theme.hover : "transparent"
            onHeightChanged: if (asking) Qt.callLater(menuBox.reveal, row)
            onAskingChanged: if (asking) password.forceActiveFocus()
            // Asked again after a wrong one, the field takes the keyboard back for the next try.
            onAskAgainChanged: if (asking) password.forceActiveFocus()
            Component.onCompleted: if (asking) password.forceActiveFocus()

            MouseArea {
              id: rowArea

              objectName: `row:${row.modelData.title}`
              width: parent.width
              height: 32
              hoverEnabled: true
              cursorShape: (menuBox.key === "output" || menuBox.key === "input") && row.modelData.current ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: root.choose(menuBox.key, row.modelData)
            }

            Glyph {
              id: lead

              x: 8
              y: 7
              visible: row.modelData.glyph !== ""
              path: row.modelData.glyph
              size: 18
              color: Theme.fg
            }

            Text {
              id: name

              x: lead.visible ? 34 : 10
              y: 16 - height / 2
              width: Math.min(implicitWidth, parent.width - x - trailing.width - (lock.visible ? 40 : 20))
              text: row.modelData.title
              textFormat: Text.PlainText
              maximumLineCount: 1
              elide: Text.ElideRight
              color: Theme.fg
              font: row.modelData.current ? Theme.heading : Theme.body
            }

            Glyph {
              id: lock

              anchors.left: name.right
              anchors.leftMargin: 6
              y: 9
              visible: row.modelData.lock ?? false
              path: Symbols.lockFilled
              size: 14
              color: Theme.fgDim
            }

            Row {
              id: trailing

              anchors.right: parent.right
              anchors.rightMargin: 8
              y: 16 - height / 2
              spacing: 8

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, row.width * (row.modelData.bad ? 0.62 : 0.5))
                visible: (row.modelData.note ?? "") !== "" && !signIn.visible
                text: row.modelData.note ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: row.modelData.bad ? Theme.destructive : Theme.fgDim
                font: Theme.caption
              }

              Glyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.current === true && row.modelData.toggle === undefined && row.modelData.tick !== false
                path: root.check
                size: 18
                color: Theme.accentBg
              }

              Switch {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.toggle !== undefined
                checked: row.modelData.toggle ?? false
                scale: 0.85
                onClicked: root.choose(menuBox.key, row.modelData)
              }

              // Something else than the row's own click: the captive portal's sign-in.
              Button {
                id: signIn

                objectName: "sign-in"
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 26
                padding: 10
                visible: (row.modelData.action ?? "") !== ""
                text: row.modelData.action ?? ""
                font: Theme.caption
                onClicked: Net.signIn()
              }
            }

            Row {
              visible: row.asking
              x: 10
              y: 36
              width: parent.width - 20
              spacing: 8

              Rectangle {
                width: parent.width - connect.width - parent.spacing
                height: 32
                radius: Theme.smallRadius
                color: Theme.bg
                border.width: 2
                border.color: Theme.accentBg

                TextInput {
                  id: password

                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.right: eye.left
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  echoMode: eye.shown ? TextInput.Normal : TextInput.Password
                  color: Theme.fg
                  font: Theme.body
                  clip: true
                  onAccepted: if (connect.enabled) connect.clicked(Qt.LeftButton)
                }

                Text {
                  anchors.fill: password
                  verticalAlignment: Text.AlignVCenter
                  visible: password.text === ""
                  text: "Password"
                  color: Theme.fgDim
                  font: Theme.body
                }

                Item {
                  id: eye

                  property bool shown: false

                  anchors.right: parent.right
                  width: 32
                  height: parent.height

                  Glyph {
                    anchors.centerIn: parent
                    path: eye.shown ? Symbols.visibilityOff : Symbols.visibility
                    size: 18
                    color: Theme.fgDim
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: eye.shown = !eye.shown
                  }
                }
              }

              Button {
                id: connect

                implicitHeight: 32
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

      Column {
        id: foot

        visible: menuBox.footer.length > 0
        width: parent.width

        Repeater {
          model: menuBox.footer

          Rectangle {
            id: action

            required property string modelData

            width: foot.width
            height: 32
            radius: Theme.smallRadius
            color: actionArea.containsMouse ? Theme.hover : "transparent"

            Text {
              x: 10
              anchors.verticalCenter: parent.verticalCenter
              text: action.modelData
              color: Theme.fg
              font: Theme.body
            }

            MouseArea {
              id: actionArea

              objectName: `action:${action.modelData}`
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: menuBox.act(action.modelData)
            }
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
          path: Volume.off
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

    Level {
      width: parent.width
      visible: NightLight.present && NightLight.on
      glyph: Symbols.nightLight
      value: NightLight.strength
      onMoved: value => NightLight.setStrength(value)
      onStepped: notches => NightLight.setStrength(NightLight.strength + notches * 0.05)
    }
  }

  component MediaCard: Rectangle {
    implicitHeight: 76
    radius: Theme.cardRadius
    color: Theme.card

    Rectangle {
      id: art

      x: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 56
      height: 56
      radius: Theme.buttonRadius
      color: Theme.button
      clip: true

      Glyph {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        path: Symbols.music
        size: 28
        color: Theme.fgDim
      }

      Image {
        id: cover

        anchors.fill: parent
        visible: status === Image.Ready
        source: Media.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(112, 112)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }

    Column {
      anchors.left: art.right
      anchors.leftMargin: 12
      anchors.right: buttons.left
      anchors.rightMargin: 8
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
        color: Theme.fgDim
        font: Theme.body
      }

      Rectangle {
        width: parent.width
        height: 4
        radius: height / 2
        visible: (Media.player?.lengthSupported ?? false) && Media.player.length > 0
        color: Theme.trough

        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, (Media.player?.position ?? 0) / Math.max(1, Media.player?.length ?? 1)))
          height: parent.height
          radius: parent.radius
          color: Theme.fg
        }
      }
    }

    Row {
      id: buttons

      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter

      Button {
        flat: true
        radius: height / 2
        padding: 0
        enabled: Media.player?.canGoPrevious ?? false
        opacity: enabled ? 1 : 0.5
        glyph: Symbols.previous
        glyphSize: 22
        onClicked: Media.player?.previous()
      }

      Button {
        radius: height / 2
        padding: 0
        enabled: Media.player?.canTogglePlaying ?? false
        opacity: enabled ? 1 : 0.5
        glyph: Media.player?.isPlaying ? Symbols.pause : Symbols.play
        glyphSize: 22
        onClicked: Media.player?.togglePlaying()
      }

      Button {
        flat: true
        radius: height / 2
        padding: 0
        enabled: Media.player?.canGoNext ?? false
        opacity: enabled ? 1 : 0.5
        glyph: Symbols.next
        glyphSize: 22
        onClicked: Media.player?.next()
      }
    }
  }

  Card {
    id: box

    x: Math.max(Theme.gap, Math.min(root.anchorX - width / 2, root.width - width - Theme.gap))
    y: root.top + Theme.gap
    width: Math.min(Math.round(28 * Theme.em), root.width - 2 * Theme.gap)
    height: Math.min(column.implicitHeight + 2 * Theme.padding, root.available)
    radius: Theme.cardRadius
    focus: true

    Rectangle {
      anchors.right: parent.right
      anchors.rightMargin: 3
      y: Theme.padding + scroller.visibleArea.yPosition * scroller.height
      z: 1
      width: 4
      height: scroller.visibleArea.heightRatio * scroller.height
      radius: width / 2
      color: Theme.fgDim
      visible: scroller.interactive
    }

    Flickable {
      id: scroller

      anchors.fill: parent
      anchors.margins: Theme.padding
      contentHeight: column.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      Column {
        id: column

        // Everything but the open menu, which takes what is left of the screen; measured a frame later, as the menu's own height feeds back into the column.
        property real fixed: 0

        function measure(): void {
          column.fixed = column.children.filter(child => child.menu === false).reduce((sum, child) => sum + child.height + column.spacing, 0);
        }

        onChildrenChanged: Qt.callLater(column.measure)

        width: scroller.width
        spacing: 12

        Repeater {
          model: ScriptModel {
            values: root.sections
            objectProp: "id"
          }

          Loader {
            id: section

            required property var modelData
            readonly property bool menu: modelData.kind === "menu"

            width: column.width
            onHeightChanged: if (!menu) Qt.callLater(column.measure)
            Component.onCompleted: Qt.callLater(column.measure)
            sourceComponent: ({ levels: levels, toggles: toggleRow, menu: menuSection, media: media })[modelData.kind]

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
                limit: root.available - 2 * Theme.padding - column.fixed
              }
            }

            Component {
              id: toggleRow

              Row {
                spacing: 8

                Repeater {
                  model: ScriptModel {
                    values: section.modelData.items
                    objectProp: "key"
                  }

                  Pill {
                    required property var modelData

                    width: (column.width - 8) / 2
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
