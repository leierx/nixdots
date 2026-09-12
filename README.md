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
top: {
  flake.modules.nixos.git.programs.git.enable = true;
  flake.modules.homeManager.git = { ... };
}
```

## Structure

```
flake.nix          evaluates modules/ and returns config.flake
import-tree.nix    imports every .nix file under a directory

modules/
  flake/           the substrate: output surface, perSystem, host builders,
                   identity, checks, offline installer
  features/        one file per feature, covering every class it applies to
  profiles/        base and workstation: named groups of features
  theme/           palette, fonts, gtk, qt, cursor
  hosts/           one directory per machine
```

Rules:

- A directory is a domain, a file is a feature, a feature spans classes.
- Nothing is implicit: a host's `imports` list is the whole machine. Profiles
  are ordinary aspects, so a host may take both, one, or none.
- Values are shared through the top-level configuration, never `specialArgs`
  (`modules/theme/palette.nix`, `modules/flake/identity.nix`).
- Modules are tagged with their `_class`, so a home-manager module loaded into
  a NixOS configuration is a type error.

## Hosts

```nix
# modules/hosts/thonkpad/imports.nix
{ config, ... }:
{
  nixosHosts.thonkpad = { };

  flake.modules.nixos."nixosConfigurations/thonkpad".imports = with config.flake.modules.nixos; [
    base
    workstation
    grub
    efi
    gaming
  ];
}
```

The rest of `modules/hosts/thonkpad/` (`configuration`, `hardware`, `disko`,
`monitors`) contributes to the same aspect. A profile's NixOS half pulls in its
home-manager half, so `workstation` configures the session too.

## Building

```bash
host=thonkpad

sudo nixos-rebuild switch --flake ".#$host"
nix build ".#nixosConfigurations.$host.config.system.build.toplevel"

# offline installer ISO carrying that host's toplevel and disko script
nix build ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"

nix flake check    # formatting + evaluation of every host
nix fmt            # nixfmt-tree
```

## Using a feature elsewhere

```nix
{ inputs, ... }:
{
  imports = [
    inputs.nixdots.modules.nixos.hyprland          # compositor, portals, pam
    inputs.nixdots.modules.homeManager.hyprland    # session, waybar, mako, binds
  ];
}
```

Features pin their dependencies to this flake's inputs (hyprland, disko,
nixpkgs-unstable). The home-manager half of `hyprland` reads `osConfig` for the
compositor package and therefore needs the NixOS half.
