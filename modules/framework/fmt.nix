{
  config,
  inputs,
  lib,
  ...
}:
let
  usedSystems = lib.pipe config.systems [
    (lib.mapAttrsToList (_: c: c.platform))
    lib.unique
  ];

  formatCheck =
    pkgs:
    pkgs.runCommand "nixfmt-check"
      {
        src = ../..;
        nativeBuildInputs = [ pkgs.nixfmt ];
      }
      ''
        find "$src" -name '*.nix' -type f -print0 | xargs -0 nixfmt --check
        touch "$out"
      '';

  # forces module-system evaluation of every nixos host + installer without building
  # (.name reads the derivation data, so the configs get evaluated but not realized)
  evalCheck =
    pkgs:
    let
      toplevelNames = lib.mapAttrsToList (
        _: c: c.config.system.build.toplevel.name
      ) config.nixosConfigurations;
    in
    pkgs.runCommand "eval-check" { inherit toplevelNames; } ''
      echo "$toplevelNames" > "$out"
    '';
in
{
  options = {
    formatter = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Flake formatter output, keyed by system";
    };

    checks = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
      default = { };
      description = "Flake checks, keyed by system then name";
    };
  };

  config = {
    formatter = lib.genAttrs usedSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree);

    checks = lib.genAttrs usedSystems (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in
      {
        format = formatCheck pkgs;
        eval = evalCheck pkgs;
      }
    );
  };
}
