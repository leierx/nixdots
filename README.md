# nixdots

Personal NixOS configuration. Flake-parts-free, loosely dendritic.

## How it works

`flake.nix` runs `lib.evalModules` on every `.nix` file under `modules/`
(via `import-tree.nix`). The result's `config` becomes the flake's
output.

Each file is a small module that contributes one thing under
`modules.{nixos,homeManager,overlays}.<name>`. `flake/build.nix`
turns each entry in `modules.nixos.hosts.*` into a real
`nixosConfiguration`.

## Layout

```
flake.nix                Inputs + outputs glue
import-tree.nix          Recursively imports every .nix under modules/
assets/                  Static files (wallpapers, neovim config, etc.)
modules/
  flake/                 Internal plumbing: option declarations + build
  hosts/<name>/          Per-host modules (configuration, hardware, disko, ...)
  profiles/              Composable bundles of modules (minimal, graphical)
  gui/                   Display manager, fonts, theming, hyprland
  overlays/              Modules that set nixpkgs.overlays
  *.nix                  Standalone reusable modules
```

## Conventions

- Every module owns its own options under `flakeModules.<module>.*`.
- Modules are independent — no cross-module option references.
- Filenames are kebab-case; Nix attributes are camelCase.
- Files starting with `_` are skipped by `import-tree.nix`.
- **No relative path imports between files.** Modules never reference
  another file by path (`./foo.nix`, `../assets/x`). Static files live
  in the `assets` flake input and are accessed via `inputs.assets`.
  Cross-module composition happens only through option values and
  `config.modules.*`.

## Adding a host

1. Create `modules/hosts/<name>/configuration.nix` defining
   `modules.nixos.hosts.<name>`.
2. Import the profiles or individual modules you want.
3. Build: `sudo nixos-rebuild switch --flake .#<name>`.

## TODO

- [ ]
