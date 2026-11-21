dir=${1:?usage: qs-design-lint SHELL_DIR}
cd "$dir"

# What the design standards in AGENTS.md leave to a file on purpose: a file or component, a rule, and why.
allow='power/PowerMenu.qml	radius	the power tiles are large squircles, no role of Theme'"'"'s
launcher/LayoutDiagram.qml	font	outputs and their labels are drawn to scale
Preview	component	every launcher mode draws its own preview'

files=$(find . -name '*.qml' -not -path './nix/*' -not -path './common/Theme.qml' | sed 's|^\./||' | sort)

findings() {
  local file
  for file in $files; do
    grep -nP '"#[0-9a-fA-F]{3,8}"|Qt\.(rgba|hsla|hsva|lighter|darker)\(|Qt\.tint\((?!Theme\.)' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a colour of its own rather than Theme's\tcolour|" || true
    grep -nP '\bradius: [0-9.]*[1-9][0-9.]*\s*$' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a radius typed out rather than Theme's or height / 2\tradius|" || true
    awk -v file="$file" '/ColorAnimation \{/ { inside = 1 } inside && /duration: [0-9]/ { printf "%s:%d: a colour fading over its own time rather than Theme.fade\tfade\n", file, NR } inside && /\}/ { inside = 0 }' "$file"
    grep -nP '\bduration: [0-9]' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a duration typed out rather than Theme's fade, move, open, close, tap or settle\tmotion|" || true
    grep -nP 'pointSize|pixelSize|Qt\.font\(|font\.(family|weight)' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a font of its own rather than Theme's\tfont|" || true
    grep -nP '"[mM][0-9]' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: an icon path rather than one of Symbols', which the build writes\ticon|" || true
    [ "$file" = common/Card.qml ] || grep -nP '^\s*Shadow \{' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a shadow on something that is not a Card\tshadow|" || true
    [ "$file" = common/ExpanderArrow.qml ] || grep -nP '^\s*rotation:' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: something turned by hand rather than an ExpanderArrow's pointing\tturn|" || true
    grep -nP '\.flatMap\(|\.flat\(' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: Qt's JavaScript has no flatMap or flat\tjs|" || true
    awk -v file="$file" '/^\s*IconButton \{/ { inside = 1; depth = 0; found = 0; start = NR } inside { depth += gsub(/\{/, "{"); depth -= gsub(/\}/, "}"); if (/^\s*tooltip:/) found = 1; if (depth == 0) { if (!found) printf "%s:%d: an icon-only button with no tooltip, which the HIG asks of each\ttooltip\n", file, start; inside = 0 } }' "$file"
    awk -v file="$file" '/^\s*Glyph \{/ { inside = 1 } inside && /^\s*size: [0-9]+\s*$/ && $2 !~ /^(16|32|64|128)$/ { printf "%s:%d: a symbol at %s px, where Adwaita draws at 16, 32, 64 or 128\ticon\n", file, NR, $2 } inside && /^\s*\}/ { inside = 0 }' "$file"
    grep -nP 'glyphSize: (?!(16|32|64|128)\s*$)[0-9]+' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a symbol at a size Adwaita's do not draw at\ticon|" || true
    grep -nP '^(?!\s*//).*["\x60][^"\x60]*[A-Za-z)]\.["\x60]' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: text ending in a full stop, which the HIG leaves off\twords|" || true
    grep -nP '(Settings|Preferences|Properties)…["\x60]' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: an ellipsis on a settings item, which asks for no more input\twords|" || true
    grep -nP '^(?!\s*//).*["\x60][^"\x60]*(\}|\d) (%|h|min|s|ms|Hz|[KMGT]i?B|[KMG]b/s)(?![A-Za-z0-9.])' "$file" | grep -v -e 'console\.' -e 'path: "' | sed "s|^\([0-9]*\):.*|$file:\1: a plain space before a unit rather than Theme.unit's narrow no-break space\twords|" || true
  done
  # A component drawn twice drifts apart: one in common/, or one name per thing.
  for file in $files; do grep -oP '^\s*component \K\w+' "$file" | sed "s|$|\t$file|" || true; done |
    awk -F '\t' -v common="$(find common -name '*.qml' -printf '%f\n' | sed 's/\.qml$//' | paste -sd ' ')" '
      BEGIN { split(common, names, " "); for (i in names) shared[names[i]] = 1 }
      { where[$1] = where[$1] ? where[$1] ", " $2 : $2; count[$1]++ }
      END { for (name in count) if (count[name] > 1 || name in shared) printf "%s: component %s is drawn in %s%s\t%s\n", where[name], name, where[name], name in shared ? " and common/" : "", "component:" name }'
}

found=$(findings | while IFS=$'\t' read -r message rule; do
  file=${message%%:*}
  if printf '%s\n' "$allow" | awk -F '\t' -v file="$file" -v rule="$rule" '($1 == file && $2 == rule) || (rule == "component:" $1 && $2 == "component") { hit = 1 } END { exit !hit }'; then continue; fi
  echo "$message [design-${rule%%:*}]"
done)
[ -z "$found" ] || { echo "$found"; exit 1; }
