shell=${1:?usage: qs-lint SHELL_DIR}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -r "$shell" "$work/qs"
chmod -R u+w "$work/qs"

# Quickshell resolves `qs.<dir>` imports itself; qmllint needs a qmldir per directory.
find "$work/qs" -type d | while read -r dir; do
  module=qs$(realpath --relative-to="$work/qs" "$dir" | sed 's|^\.$||; s|^|/|; s|^/$||' | tr / .)
  {
    echo "module $module"
    for file in "$dir"/*.qml; do
      [ -e "$file" ] || continue
      name=$(basename "$file" .qml)
      if grep -q '^pragma Singleton' "$file"; then
        echo "singleton $name 1.0 $name.qml"
      else
        echo "$name 1.0 $name.qml"
      fi
    done
  } > "$dir/qmldir"
done

# Quickshell's type info, mended: _GlobalShortcuts forgets it depends on Quickshell (GlobalShortcut's base),
# opaque stubs in submodules hide the real types, and FileView.adapter names its type unqualified.
cp -r "$quickshellQml" "$work/qml"
chmod -R u+w "$work/qml"
find "$work/qml/Quickshell" -mindepth 2 -name qmldir | while read -r qmldir; do
  grep -qx 'depends Quickshell' "$qmldir" || echo 'depends Quickshell' >> "$qmldir"
done
core=$(grep -oP '^        name: "\K[^"]+' "$work/qml/Quickshell/quickshell-core.qmltypes")
find "$work/qml/Quickshell" -mindepth 2 -name '*.qmltypes' | while read -r types; do
  awk -v core="$core" '
    BEGIN { split(core, names, "\n"); for (i in names) defined[names[i]] = 1 }
    /^    Component \{ isTypeOpaque: true; name: "/ { split($0, parts, "\""); if (parts[2] in defined) next }
    { print }
  ' "$types" > "$types.new"
  mv "$types.new" "$types"
done
sed -i 's/type: "FileViewAdapter"/type: "qs::io::FileViewAdapter"/' "$work/qml/Quickshell/Io/quickshell-io.qmltypes"
sed -i '/name: "qs::dbus::dbusmenu::DBusMenuHandle"/a\        prototype: "qs::menu::QsMenuHandle"' \
  "$work/qml/Quickshell/Services/SystemTray/quickshell-service-statusnotifier.qmltypes"

mapfile -t files < <(find "$work/qs" -name '*.qml' | sort)

# Quickshell's types say PanelWindow cannot be created, though every shell creates one.
# JSON, as the text output leaves out some files' warnings while still failing on them.
status=0
qmllint \
  -I "$work" -I "$work/qml" -I "$qtQml" \
  --max-warnings 0 \
  --uncreatable-type disable \
  --json "$work/lint.json" \
  "${files[@]}" || status=$?
jq -r --arg work "$work/" '
  .files[] | (.filename | ltrimstr($work)) as $file
  | .warnings[] | select(.type != "info")
  | "\($file):\(.line // 0):\(.column // 0): \(.message) [\(.id // .type)]"
' "$work/lint.json"

# The design standards in AGENTS.md, as far as the source shows them.
qs-design-lint "$work/qs" || status=1
exit "$status"
