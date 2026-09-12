# The primary user, across every class: the NixOS account, the home-manager
# identity, and root's locked password.
top@{ lib, ... }:
let
  inherit (top.config.identity) username;
in
{
  flake.modules.nixos.users =
    { config, pkgs, ... }:
    {
      users.groups.${username} = { };

      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        createHome = true;
        homeMode = "0770";
        group = username;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "input"
        ]
        ++ lib.optional config.virtualisation.podman.enable "podman"
        ++ lib.optional config.virtualisation.incus.enable "incus-admin";

        initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
      };

      # login shell; the configuration itself lives in the zsh feature
      programs.zsh.enable = true;
      programs.starship.enable = true;

      users.users.root.hashedPassword = "!";
    };

  flake.modules.homeManager.users =
    { pkgs, ... }:
    {
      home = {
        username = lib.mkDefault username;
        homeDirectory = lib.mkDefault (
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}"
        );
      };
    };
}
