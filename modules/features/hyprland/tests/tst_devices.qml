import QtQuick
import QtTest
import "../quickshell/controls/devices.js" as Devices

TestCase {
  name: "Devices"

  function test_form_factor_first() {
    compare(Devices.kind({ "device.form-factor": "headset", "node.description": "Speakers", "device.id": 3 }, false, false), "headset");
    compare(Devices.kind({ "device.form-factor": "headphone", "device.id": 3 }, false, false), "headphones");
    compare(Devices.kind({ "device.form-factor": "webcam", "node.description": "K438 Mono", "device.id": 79 }, true, false), "webcam");
    compare(Devices.kind({ "device.icon-name": "camera-web-analog-usb", "device.id": 79 }, true, false), "webcam");
  }

  function test_names() {
    compare(Devices.kind({ "node.description": "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI)", "device.id": 46 }, false, false), "display");
    compare(Devices.kind({ "node.description": "HDMI / DisplayPort" }, false, false), "display");
    compare(Devices.kind({ "node.description": "Headset Microphone" }, true, false), "headset");
    compare(Devices.kind({ "node.description": "Headphones" }, false, false), "headphones");
    compare(Devices.kind({ "node.description": "Microphone" }, true, false), "microphone");
    compare(Devices.kind({ "node.description": "Speakers" }, false, false), "speaker");
  }

  function test_a_device_both_ways() {
    const headset = { "node.description": "PRO X 2 LIGHTSPEED Analog Stereo", "device.id": 47, "device.bus": "usb" };
    compare(Devices.kind(headset, false, true), "headset");
    compare(Devices.kind(headset, true, true), "headset");
    compare(Devices.kind(headset, false, false), "speaker");
    const onboard = { "node.description": "Starship/Matisse HD Audio Controller Analog Stereo", "device.id": 48, "device.bus": "pci" };
    compare(Devices.kind(onboard, false, true), "speaker");
    compare(Devices.kind(onboard, true, true), "microphone");
    compare(Devices.kind({ "node.name": "bluez_output.AA_BB", "device.id": 90, "device.api": "bluez5" }, false, true), "headset");
  }

  function test_virtual_and_missing() {
    compare(Devices.kind({ "node.description": "Noise Cancelling" }, true, false), "virtual");
    compare(Devices.kind({}, false, false), "virtual");
    compare(Devices.kind(undefined, false, false), "virtual");
    compare(Devices.kind(null, true, false), "virtual");
  }
}
