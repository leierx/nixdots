# Identity and platform defaults every home-manager configuration needs,
# whether it is evaluated inside NixOS, inside nix-darwin, or standalone.
top: {
  flake.modules.homeManager.core =
    { lib, pkgs, ... }:
    let
      inherit (top.config.me) username;
    in
    {
      home = {
        username = lib.mkDefault username;
        homeDirectory = lib.mkDefault (
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}"
        );
        stateVersion = lib.mkDefault lib.trivial.release;
      };
    };
}
