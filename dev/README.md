# quickshell experiments

Isolated dev area, own flake, not wired into the root `flake.nix`.

Run from this directory (`dev/`):

```sh
nix develop          # drops you into a shell with `quickshell` on PATH
quickshell -p ./quickshell/shell.qml   # edit + save, the bar hot-reloads
```

Quick one-shot (store snapshot, no live reload):

```sh
nix run              # = quickshell -p ./quickshell/shell.qml
```

Note: your regular waybar still runs and reserves the same screen edge —
kill it while testing this bar (or it will double up).