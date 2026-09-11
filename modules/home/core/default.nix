# Identity and platform defaults every home-manager configuration needs,
# whether it is evaluated inside NixOS, inside nix-darwin, or standalone.
{
  flake.modules.homeManager.core =
    { lib, pkgs, ... }:
    {
      home = {
        username = lib.mkDefault "leier";
        homeDirectory = lib.mkDefault (
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/leier" else "/home/leier"
        );
        stateVersion = lib.mkDefault lib.trivial.release;
      };
    };
}
