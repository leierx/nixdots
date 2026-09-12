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
  features/        one flat file per feature, covering every class it
                   applies to; a directory only when the feature has parts
                   (hyprland/, neovim/)
  profiles/        base and workstation: named groups of features
  theme/           palette, fonts, gtk, qt, cursor
  hosts/           one directory per machine
```

Rules:

- A file is a feature, and a feature spans every class it touches.
- A host's `imports` list is the whole machine. Profiles are ordinary
  aspects, so a host may take both, one, or none; the builders add only the
  hostname, platform and a `stateVersion` default, all overridable.
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
    gaming
  ];
}
```

The rest of `modules/hosts/thonkpad/` (`configuration`, `hardware`, `disko`,
`monitors`) contributes to the same aspect. A profile's NixOS half pulls in its
home-manager half, so `workstation` configures the session too.

`base` boots with GRUB on EFI; a host that wants the alternative adds
`systemd-boot`, which forces GRUB off.

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

## Branches

`main` is the configuration. `quickshell` is an unrelated branch holding the
quickshell bar experiments and their own flake.
