dir=${1:?usage: qs-design-lint SHELL_DIR}
cd "$dir"

# What the design standards in AGENTS.md leave to a file on purpose: a file or component, a rule, and why.
allow='bar/Battery.qml	radius	a meter drawn to its own scale
power/PowerMenu.qml	radius	the power tiles are large squircles, no role of Theme'"'"'s
Slider	component	the volume popup'"'"'s slider and the OSD'"'"'s level meter are different things
Preview	component	every launcher mode draws its own preview'

files=$(find . -name '*.qml' -not -path './nix/*' -not -path './common/Theme.qml' | sed 's|^\./||' | sort)

findings() {
  local file
  for file in $files; do
    grep -nP '"#[0-9a-fA-F]{3,8}"|Qt\.(rgba|hsla|hsva|lighter|darker)\(|Qt\.tint\((?!Theme\.)' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a colour of its own rather than Theme's\tcolour|" || true
    grep -nP '\bradius: [0-9.]*[1-9][0-9.]*\s*$' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: a radius typed out rather than Theme's or height / 2\tradius|" || true
    awk -v file="$file" '/ColorAnimation \{/ { inside = 1 } inside && /duration: [0-9]/ { printf "%s:%d: a colour fading over its own time rather than Theme.fade\tfade\n", file, NR } inside && /\}/ { inside = 0 }' "$file"
    grep -nP '\.flatMap\(|\.flat\(' "$file" | sed "s|^\([0-9]*\):.*|$file:\1: Qt's JavaScript has no flatMap or flat\tjs|" || true
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
