import QtQuick
// Its plugin carries the shader in its resources.
import QtQuick.Effects // qmllint disable unused-imports

ShaderEffect {
  id: root

  property real spreadBy: 0
  readonly property real blurAmount: 4
  readonly property real pad: 2 * blurAmount + 2 * spreadBy
  readonly property real parentRadius: (parent as Rectangle)?.radius ?? 0

  x: -pad * 0.5
  y: -pad * 0.5 + 2
  width: (parent?.width ?? 0) + pad
  height: (parent?.height ?? 0) + pad
  z: -1

  readonly property vector3d iResolution: Qt.vector3d(width, height, 1.0)
  readonly property point rectSize: Qt.point(width * 0.5 - (blurAmount * 1.8 + 1.0), height * 0.5 - (blurAmount * 1.8 + 1.0))
  readonly property color color: Theme.shadowColor
  readonly property real radius: {
    const w = parent?.width ?? 0;
    const h = parent?.height ?? 0;
    const maxR = Math.min(w, h) * 0.5 + spreadBy * 2 - blurAmount * 0.75;
    let sr = parentRadius + spreadBy;
    if (parentRadius < spreadBy && spreadBy !== 0) {
      const r = parentRadius / spreadBy - 1;
      sr = parentRadius + spreadBy * (1 + r * r * r);
    }
    return Math.min(Math.max(0, sr - blurAmount * 0.75), maxR);
  }
  readonly property real blur: blurAmount * 2.1 + 1.0

  vertexShader: "qrc:/data/shaders/rectangularshadow.vert.qsb"
  fragmentShader: "qrc:/data/shaders/rectangularshadow.frag.qsb"
}
