{ config, ... }:
{
  flake.modules.nixos.user =
    { pkgs, ... }:
    let
      user = config.flake.settings.user;
    in
    {
      users.root.hashedPassword = "!";

      users.groups.${user.username} = { };

      users.users.${user.username} = {
        isNormalUser = true;
        home = user.homeDirectory;
        createHome = true;
        homeMode = "0770";
        shell = pkgs.zsh;
        group = user.username;

        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "lp"
          "scanner"
          "libvirtd"
          "kvm"
          "podman"
          "wireshark"
          "input"
        ];

        description = user.username;

        initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
      };
    };
}
