import QtQuick
import QtQuick.Shapes
import qs.common

// A strip along the top with three tabs hanging from it, flared into it; flat at the screen's edges.
Shape {
  id: root

  property real strip: 7
  property real flare: 15
  property real flareHeight: 13
  property real radius: 13
  property real leftWidth: 0
  property real centerX: 0
  property real centerWidth: 0
  property real rightWidth: 0

  readonly property string path: {
    const w = width, h = height, t = strip, fw = flare, fh = flareHeight, r = radius;
    const k = 0.45;
    // From the strip at x down a tab's left side into its bottom; up a tab's right side into the strip at x.
    const down = x => `C ${x + fw * (1 - k)} ${t}, ${x + fw} ${t + fh * k}, ${x + fw} ${t + fh} L ${x + fw} ${h - r} C ${x + fw} ${h - r * k}, ${x + fw + r * k} ${h}, ${x + fw + r} ${h} `;
    const up = x => `L ${x - fw - r} ${h} C ${x - fw - r * k} ${h}, ${x - fw} ${h - r * k}, ${x - fw} ${h - r} L ${x - fw} ${t + fh} C ${x - fw} ${t + fh * k}, ${x - fw * (1 - k)} ${t}, ${x} ${t} `;
    const rx = w - rightWidth;
    // No right tab while it has nothing to hold.
    const end = rightWidth > 0 ? `L ${rx} ${t} ${down(rx)} L ${w} ${h}` : `L ${w} ${t}`;
    return `M 0 0 L 0 ${h} ${up(leftWidth)} L ${centerX} ${t} ${down(centerX)} ${up(centerX + centerWidth)} ${end} L ${w} 0 Z`;
  }

  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: Theme.panel
    strokeColor: "transparent"

    PathSvg {
      path: root.path
    }
  }
}
