// The Symbols singleton from GNOME's symbolic SVGs, one per line of symbols.tsv (name, icon); quickshell.nix runs it at build time.
// node scripts/symbols.mjs SVGO_LIB_DIR ICON_DIR... > Symbols.qml, the first directory holding an icon winning
import { readFileSync, readdirSync, statSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const [svgoDir, ...iconDirs] = process.argv.slice(2);
const { optimize } = await import(join(svgoDir, "lib/svgo-node.js"));
const here = dirname(fileURLToPath(import.meta.url));

const files = {};
for (const iconDir of iconDirs) {
  for (const sub of readdirSync(iconDir)) {
    const path = join(iconDir, sub);
    if (statSync(path).isDirectory()) for (const file of readdirSync(path)) files[file] ??= join(path, file);
  }
}

const lines = [];
for (const row of readFileSync(join(here, "symbols.tsv"), "utf8").trim().split("\n")) {
  const [name, icon] = row.split("\t");
  const file = files[`${icon}-symbolic.svg`];
  if (!file) throw new Error(`no -symbolic in `);
  // Shapes and transforms become plain path data, which is all a Glyph draws.
  const svg = optimize(readFileSync(file, "utf8"), { multipass: true, plugins: [
    { name: "preset-default", params: { overrides: { mergePaths: false, convertPathData: { applyTransforms: true, floatPrecision: 3 } } } },
    "convertShapeToPath", "convertTransform", "moveGroupAttrsToElems",
  ] }).data;
  if (/<(rect|circle|ellipse|polygon|line|use)\b|transform=/.test(svg)) throw new Error(`${icon} keeps shapes or transforms`);
  const solid = [], faint = [];
  for (const [, attrs] of svg.matchAll(/<path\b([^>]*)\/?>/g)) {
    const d = /\sd="([^"]*)"/.exec(attrs)?.[1];
    if (!d) continue;
    const opacity = parseFloat(/(?:fill-)?opacity="([^"]*)"/.exec(attrs)?.[1] ?? "1");
    (opacity < 0.99 ? faint : solid).push(d);
  }
  lines.push(`  readonly property string ${name}: "${faint.length ? `${solid.join(" ")}|${faint.join(" ")}` : solid.join(" ")}"`);
}

console.log(`pragma Singleton

import Quickshell

// GNOME's symbolic icons (adwaita-icon-theme and gnome-shell, CC BY-SA 3.0), built by scripts/symbols.mjs from scripts/symbols.tsv: a 16 px box; a path's faint part follows a "|".
Singleton {
${lines.join("\n")}
}`);
