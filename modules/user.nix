{ config, ... }:
let
  outerConfig = config;
in
{
  flake.modules.nixos.user =
    { config, lib, ... }:
    let
      cfg = config.dot.user;
    in
    {
      options.dot.user = {
        name = lib.mkOption {
          type = lib.types.singleLineStr;
          default = outerConfig.flake.defaults.username;
          description = "Primary user account name (Unix username)";
        };
      };

      config = {
        users.groups.${cfg.name} = { };

        users.users.${cfg.name} = {
          isNormalUser = true;
          home = "/home/${cfg.name}";
          createHome = true;
          homeMode = "0770";
          group = cfg.name;

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
    };
}
