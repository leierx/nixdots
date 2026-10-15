{ inputs, ... }:
{
  flake.modules.homeManager.nix-index =
    { pkgs, ... }:
    let
      packages = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index-database.comma.enable = true;
      programs.nix-index.package = packages.nix-index-with-small-db;
      # the cache symlink would pull in the full database
      programs.nix-index.symlinkToCacheHome = false;
    };
}
