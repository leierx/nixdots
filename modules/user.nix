{ config, ... }:
let
  user = config.flake.meta.user;
in
{
  flake.modules.nixos.user = {
    users.groups.${user.username} = { };

    users.users.${user.username} = {
      isNormalUser = true;
      home = user.homeDirectory;
      createHome = true;
      homeMode = "0770";
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
        "incus-admin"
        "podman"
        "wireshark"
        "input"
      ];

      initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
    };
  };
}
