# nixdots

Personal NixOS configuration. Flake-parts-free, loosely dendritic.

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

## TODO

- [ ] move from fuzzel -> rofi-wayland eventually
- [ ] look into https://github.com/nix-community/impermanence
- [x] setup formatter for flake

