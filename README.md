# nixdots

Personal NixOS / nix-darwin / home-manager configurations, written in the
[dendritic pattern](https://github.com/mightyiam/dendritic) on a
dependency-free, hand-rolled substrate.

## The pattern

`flake.nix` evaluates **one** top-level configuration with the nixpkgs module
system. Every `.nix` file under `modules/` is a module of that configuration —
no file is imported by name, no file is a NixOS module directly.

```nix
# flake.nix
(inputs.nixpkgs.lib.evalModules {
  class = "flake";
  specialArgs.inputs = inputs;
  modules = [ (import ./import-tree.nix ./modules) ];
}).config.flake
```

Lower-level modules (NixOS, home-manager, nix-darwin) are *values* of that
configuration, stored under `flake.modules.<class>.<aspect>`:

```nix
# modules/nixos/desktop/sound.nix
{
  flake.modules.nixos.desktop = {
    services.pipewire.enable = true;
  };
}
```

Because the option type is `deferredModule`, any number of files may
contribute to the same aspect; `hyprland`, for instance, is assembled from
eight files. Each file names a *feature*, not a host or a class, and may
configure that feature across every class it touches.

Values are shared between files through the top-level configuration rather
than `specialArgs`: `modules/theme/palette.nix` declares a `palettes` option
that rofi, wezterm, waybar, mako and tmux all read.

## Substrate

Everything the pattern needs is in this repository; there is no `flake-parts`
or `import-tree` dependency.

| File | Role |
| --- | --- |
| `import-tree.nix` | recursively imports every `.nix` file under a directory |
| `modules/flake/outputs.nix` | declares the `flake.*` output surface and the class-tagged module registry |
| `modules/flake/per-system.nix` | a minimal `perSystem`, evaluated once per entry of `systems` |
| `modules/flake/nixos-hosts.nix` | builds `nixosConfigurations` from `nixosHosts.<name>` |
| `modules/flake/darwin-hosts.nix` | builds `darwinConfigurations` from `darwinHosts.<name>` |
| `modules/flake/home-configurations.nix` | builds standalone `homeConfigurations` from `homeConfigs.<name>` |
| `modules/flake/offline-installer.nix` | an offline installer ISO per NixOS host |
| `modules/flake/checks.nix` | formatting and whole-fleet evaluation checks |
| `modules/flake/identity.nix` | username, full name and email, in one place |

Modules stored in `flake.modules.<class>` are tagged with their module
`_class`, so loading a home-manager module into a NixOS configuration is a
type error rather than a flood of undeclared-option messages.

## Layout

```
modules/
  flake/     the substrate above
  nixos/     core/ and desktop/ NixOS aspects
  home/      core/ and desktop/ home-manager aspects
  darwin/    nix-darwin aspects
  theme/     cross-class theming (palette, fonts, gtk, qt, cursor)
  hosts/     one directory per machine
```

Aggregation happens only in `imports.nix` files:

```nix
# modules/nixos/core/imports.nix
{ config, ... }:
{
  flake.modules.nixos.core.imports = with config.flake.modules.nixos; [
    base-packages
    boot
    doas
    # …
  ];
}
```

## Hosts

A host is an aspect named after itself. Any file may contribute to it —
`modules/hosts/thonkpad/` splits into `imports`, `configuration`, `hardware`,
`disko`, `monitors` and `home`:

```nix
# modules/hosts/thonkpad/imports.nix
{ config, ... }:
{
  nixosHosts.thonkpad = { };

  flake.modules.nixos."nixosConfigurations/thonkpad".imports = with config.flake.modules.nixos; [
    desktop
    gaming
    efi
    grub
  ];
}
```

Home-manager is wired as a NixOS aspect: each host's user imports
`homeManager.core` plus `homeManager."homeConfigurations/<host>"`, so the
host's home configuration is written in the same host directory.

## Usage

```bash
sudo nixos-rebuild switch --flake .#thonkpad
nix flake check                 # formatting + evaluation of every host
nix fmt                         # nixfmt-tree
```

## Using individual modules elsewhere

Every aspect is published as `modules.<class>.<aspect>`:

```nix
{
  inputs.nixdots.url = "github:leier/nixdots";
}
```

```nix
# a NixOS configuration elsewhere
{ inputs, ... }:
{
  imports = [ inputs.nixdots.modules.nixos.git ];
}
```

```nix
# home-manager, standalone or nested
{ inputs, ... }:
{
  imports = [
    inputs.nixdots.modules.homeManager.hyprland # waybar, mako, hyprlock, bindings …
    inputs.nixdots.modules.homeManager.zsh
  ];
}
```

Notes:

- `modules.nixos.hyprland` is the system half only; its home-manager half is
  `modules.homeManager.hyprland`, which reads `osConfig` for the compositor package
  and therefore needs the NixOS side.
- Modules pin their dependencies to this flake's inputs (hyprland, disko,
  nixpkgs-unstable), so importing one does not mean matching versions.
- Colour choices come from `palettes` in the top-level configuration; the
  rendered output is plain options (`programs.wezterm.extraConfig` and
  friends), so overriding them downstream is ordinary module merging.

## Installers

Every NixOS host gets an `offlineInstaller-<host>` live ISO carrying that
host's toplevel and disko script:

```bash
nix build .#nixosConfigurations.offlineInstaller-thonkpad.config.system.build.isoImage
```
