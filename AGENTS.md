# nixdots

A NixOS flake configuration using flake-parts. All modules under `modules/` are
auto-imported via `import-tree.nix`, which recursively collects every `.nix` file
in that directory.

## Architecture

- `flake.nix` — entry point; delegates to flake-parts via `import-tree.nix`
- `modules/flake/` — flake-parts infrastructure (options, systems, pkgs, wiring)
- `modules/` — NixOS and Home Manager modules exposed via `flake.modules.nixos.*`
  and `flake.modules.homeManager.*`
- `modules/hosts/` — per-host configurations
- `modules/profiles/` — composable profiles (minimal, graphical)

## Module Authoring Conventions

### Never wrap a module file in a flake-parts function when no flake-parts args are needed

Each `.nix` file is imported as a flake-parts module, so the module system
accepts either a function or a plain attrset. When no flake-parts-level args
(`inputs`, `config`, etc.) are actually used, omit the outer function entirely:

```nix
# CORRECT — plain attrset, no outer wrapper needed
{
  flake.modules.nixos.foo = { pkgs, lib, ... }: {
    ...
  };
}

# WRONG — outer { ... }: adds noise with no benefit
{ ... }:
{
  flake.modules.nixos.foo = { pkgs, lib, ... }: {
    ...
  };
}
```

Only add the outer function when you actually need flake-parts args such as
`inputs`, `config` (flake-parts config), or `self`.

### Always take pkgs and lib from the NixOS/HM module args, never from flake-parts

`flake.modules.nixos.*` and `flake.modules.homeManager.*` values are NixOS /
Home Manager modules. They must receive `pkgs` and `lib` from the module system,
not by closing over them from an outer flake-parts function.

```nix
# CORRECT
{
  flake.modules.homeManager.foo = { pkgs, lib, ... }: {
    home.packages = [ pkgs.ripgrep ];
  };
}

# WRONG — pkgs/lib leak in from flake-parts scope
{ pkgs, lib, ... }:
{
  flake.modules.homeManager.foo = {
    home.packages = [ pkgs.ripgrep ];   # wrong pkgs, wrong scope
  };
}
```

This applies even though in practice `lib` from flake-parts and `lib` from the
NixOS module system resolve to the same object. The structural correctness still
matters: a module value must be either a plain attrset or a function that accepts
module args — it must never silently close over values from an outer scope.
