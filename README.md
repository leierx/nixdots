# nixdots

NixOS / nix-darwin / home-manager configurations in the
[dendritic pattern](https://github.com/mightyiam/dendritic), on a
dependency-free, hand-rolled substrate.

Every `.nix` file under `modules/` is a module of one top-level configuration.
Lower-level modules are values of that configuration, stored under
`flake.modules.<class>.<aspect>` and merged by name, so a feature is written
once across every class it touches:

```nix
# modules/features/git.nix
root: {
  flake.modules.nixos.git.programs.git.enable = true;
  flake.modules.homeManager.git = { ... };
}
```

## Using a module elsewhere

Every aspect is published as a flake output, so another flake can import
individual features by name:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.nixdots.modules.nixos.hyprland # compositor, portals, pam
    inputs.nixdots.modules.homeManager.hyprland # session, waybar, mako, binds
  ];
}
```

Features pin their dependencies to this flake's inputs (hyprland, disko,
nixpkgs-unstable). The home-manager half of `hyprland` reads `osConfig` for the
compositor package and therefore needs the NixOS half.

## Building

```bash
host=thonkpad

sudo nixos-rebuild switch --flake ".#$host"
nix build ".#nixosConfigurations.$host.config.system.build.toplevel"

# offline installer ISO carrying that host's toplevel and disko script
nix build ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"

nix flake check # formatting + evaluation of every host
nix fmt # nixfmt-tree
```

## Layout

```
flake.nix evaluates modules/ and returns config.flake
import-tree.nix imports every .nix file under a directory

modules/
  flake/ the substrate: output surface, perSystem, host builders,
                   identity, checks, offline installer
  features/ one flat file per feature, covering every class it
                   applies to; a directory only when the feature has parts
                   (hyprland/, neovim/)
  profiles/ base and workstation: named groups of features
  theme/ palette, fonts, gtk, qt, cursor
  hosts/ one directory per machine
```

`main` is the configuration. `quickshell` is an unrelated branch holding the
quickshell bar experiments and their own flake.

Technical notes for agents live in [AGENTS.md](./AGENTS.md).
