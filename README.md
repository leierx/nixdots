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

### Overriding what a module reads

Those modules read shared values — my name, my colours, my pi settings — from
this flake's top-level configuration, so importing them as above gives you my
values. To supply your own, join the evaluation instead of consuming its
result: `lib.reconfigure` takes a module (or a list of them), merges it into
the top-level configuration and hands back the same output set the flake
normally produces.

Inline, when you need one aspect:

```nix
{ inputs, lib, ... }:
{
  imports = [
    (inputs.nixdots.lib.reconfigure {
      identity.email = lib.mkForce "you@example.org";
    }).modules.homeManager.git
  ];
}
```

Bound once in a `let`, when you need several — this is the form to prefer,
since every call is a separate evaluation and taking the *same* aspect from two
of them lands two sets of definitions in one configuration:

```nix
{ inputs, lib, ... }:
let
  nixdots = inputs.nixdots.lib.reconfigure [
    {
      identity.email = lib.mkForce "you@example.org";
      identity.fullName = lib.mkForce "Your Name";
      palettes.ui.blue = lib.mkForce "#1e88e5"; # every other colour stays mine
    }
    ./my-pi-settings.nix # an ordinary module: piAgent.settings = { ... };
  ];
in
{
  imports = [
    nixdots.modules.homeManager.git
    nixdots.modules.homeManager.rofi
    nixdots.modules.homeManager.pi-agent
  ];
}
```

The rule of thumb: values I already define (`identity.*`, `palettes.*`) need
`lib.mkForce`, because a plain definition would sit at the same priority as
mine and the module system will tell you so. Values I leave empty
(`piAgent.settings`, `neovim.outOfStorePath`, `nixIndex.smallDatabase`) take a
plain definition. Either way the granularity is per key: overriding one colour
or one setting leaves the rest of mine in place.

Everything the top-level configuration declares is fair game — see
[AGENTS.md](./AGENTS.md#top-level-options) for the list — and everything the
modules themselves set is ordinary options, so `lib.mkForce` in your own
configuration remains the escape hatch for the rest.

## Options

Modules are hardcoded on purpose. An option is added only when a machine
actually needs a different value — never in anticipation of one. Until then the
value sits inline in the feature file, where it is one edit away from being
changed and one glance away from being understood; promoting it to an option
later is mechanical. A constant nobody is overriding is just indirection.

The exception is shared data, which is not an option in that sense: `identity`,
`palettes`, `systems` and the per-host `*.settings` bags are declared once at the
top level because several modules genuinely read them. Those exist because a
value is *shared*, not because a value might vary.

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
