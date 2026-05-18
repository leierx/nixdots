{ inputs, lib, ... }:
{
  options.formatter = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Flake formatter output, keyed by system";
  };

  config.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
