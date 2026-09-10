# nixdots

Personal NixOS / nix-darwin / home-manager dotfiles, built on a hand-rolled
flake-parts equivalent: `flake.nix` evaluates every module under
`modules/` with the nixpkgs module system and exposes the result as the
flake outputs.

## Layout

- `modules/framework/` — the mini-framework: option registry, system builder,
  offline installer, conventional module exports.
- `modules/bundles/` — class-keyed named collections of modules
  (`minimal`, `graphical`), consumed by `systems.<name>.bundles`.
- `modules/systems/` — declarative system definitions:
  `{ class = "nixos" | "darwin" | "home"; platform; user; bundles; modules }`.
- `modules/` — feature modules, registered under
  `modules.nixos.*`, `modules.home.*`, or `modules.darwin.*`.

## Using individual modules in your own setup

Add the flake as an input and import any single module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixdots.url = "github:leier/nixdots";
  };
}
```

NixOS modules (system side):

```nix
# configuration.nix
{ inputs, ... }: {
  imports = [ inputs.nixdots.nixosModules.git ]; # + any other module
}
```

Home-manager modules (works standalone or inside home-manager):

```nix
{ inputs, ... }: {
  home-manager.users.myuser = {
    imports = [
      inputs.nixdots.homeModules.hyprland # waybar, mako, hyprlock, bindings …
      inputs.nixdots.homeModules.zsh
    ];
  };
}
```

Only two args can be required, and both fall back to sensible defaults:

- `theme` — gone. Colors are inlined per module, so nothing to inject.
- `identity` — defaults to the author's identity. Override it in your eval:

```nix
{ _module.args.identity = { user = "you"; name = "Your Name"; email = "you@example.com"; }; }
```

Notes:

- `nixosModules.hyprland` is the system side only; its home-manager half is
  `homeModules.hyprland` (needs the NixOS side for the compositor package, so
  no standalone-HM). Our own `graphical` bundle wires both halves.
- Modules pin their dependencies to the nixdots flake inputs (hyprland,
  disko, nixpkgs-unstable), so import without worrying about versions.
- Want a different color scheme? The rendered output of each module is
  plain config options (e.g. `programs.wezterm.extraConfig`), so you can
  override or replace them in your own modules.

## Systems / installers

`systems.<name>` builds `nixosConfigurations`, `darwinConfigurations`, or
`homeConfigurations`. Every nixos host also gets an
`nixosConfigurations.offlineInstaller-<name>` live ISO carrying the host's
toplevel and disko script:

```bash
nix build .#nixosConfigurations.offlineInstaller-thonkpad.config.system.build.isoImage
```