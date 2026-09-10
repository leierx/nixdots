{ lib, ... }:
{
  modules.nixos.user =
    { config, pkgs, ... }:
    {
      users.groups.leier = { };

      users.users.leier = {
        isNormalUser = true;
        home = "/home/leier";
        createHome = true;
        homeMode = "0770";
        group = "leier";
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

      programs.zsh.enable = true; # required for the login shell
      programs.starship.enable = true;
    };
}
