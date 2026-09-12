# quickshell experiments

A quickshell status bar, with its own flake. This branch is unrelated to
`main`, which holds the NixOS / nix-darwin / home-manager configurations.

```sh
git clone -b quickshell git@github.com:leierx/nixdots.git quickshell
cd quickshell
```

Live editing:

```sh
nix develop                            # shell with `quickshell` on PATH
quickshell -p ./quickshell/shell.qml   # edit + save, the bar hot-reloads
```

One-shot from the store, no live reload:

```sh
nix run                                # = quickshell -p ./quickshell/shell.qml
```

Note: waybar reserves the same screen edge — kill it while testing this bar,
or the two will double up.
