.pragma library

// What a sound device is, from a PipeWire node's properties: its form factor, which few devices give, then its name, then a USB or Bluetooth device that both plays and records being a headset.
function kind(props, input, paired) {
  const p = props ?? {};
  const form = p["device.form-factor"] ?? "";
  const text = `${p["node.name"] ?? ""} ${p["node.description"] ?? ""} ${p["node.nick"] ?? ""}`;
  if (form === "webcam" || /^camera-web/.test(p["device.icon-name"] ?? "")) return "webcam";
  if (["headset", "hands-free", "handset"].includes(form)) return "headset";
  if (form === "headphone") return "headphones";
  if (form === "tv" || /hdmi|displayport/i.test(text)) return "display";
  if (/headset/i.test(text)) return "headset";
  if (/headphone/i.test(text)) return "headphones";
  if (/microphone/i.test(text)) return "microphone";
  if (/speaker/i.test(text)) return "speaker";
  if (p["device.id"] === undefined) return "virtual";
  if (paired && (p["device.bus"] === "usb" || p["device.bus"] === "bluetooth" || p["device.api"] === "bluez5")) return "headset";
  return input ? "microphone" : "speaker";
}
