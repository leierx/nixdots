// The Symbols singleton from Material Design Icons (Pictogrammers), one per line of symbols.tsv (name, icon); quickshell.nix runs it at build time.
// node scripts/symbols.mjs MDI_SVG_DIR > Symbols.qml
import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const [iconDir] = process.argv.slice(2);
const here = dirname(fileURLToPath(import.meta.url));

const lines = [];
for (const row of readFileSync(join(here, "symbols.tsv"), "utf8").trim().split("\n")) {
  const [name, icon] = row.split("\t");
  const svg = readFileSync(join(iconDir, `${icon}.svg`), "utf8");
  if (!/viewBox="0 0 24 24"/.test(svg)) throw new Error(`${icon} is not on the 24 px grid`);
  const paths = [...svg.matchAll(/<path\b[^>]*\sd="([^"]*)"/g)].map(match => match[1]);
  if (paths.length === 0 || /<(rect|circle|ellipse|polygon|line|use)\b|transform=/.test(svg)) throw new Error(`${icon} is not plain path data`);
  lines.push(`  readonly property string ${name}: "${paths.join(" ")}"`);
}

console.log(`pragma Singleton

import Quickshell

// Material Design Icons (Pictogrammers, Apache 2.0), built by scripts/symbols.mjs from scripts/symbols.tsv: a 24 px box.
Singleton {
${lines.join("\n")}
}`);
