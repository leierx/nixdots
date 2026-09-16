root: {
  options.nixIndex.smallDatabase = root.lib.mkOption {
    type = root.lib.types.bool;
    default = false;
    description = "Use the small nix-index database (bin/ entries only) instead of the full one.";
  };

  config.flake.modules.homeManager.nix-index =
    { pkgs, ... }:
    {
      imports = [ root.inputs.nix-index-database.homeModules.default ];

      programs.nix-index-database.comma.enable = true;
      programs.nix-index.package =
        root.inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.${
          if root.config.nixIndex.smallDatabase then "nix-index-with-small-db" else "nix-index-with-db"
        };
    };
}
