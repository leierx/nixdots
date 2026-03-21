{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.services.incus;
in
{
  options.nixdots.services.incus = {
    enable = lib.mkEnableOption "nixdots.services.incus";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.incus = {
      enable = true;
      ui.enable = lib.mkDefault false;
      agent.enable = lib.mkDefault true;
      preseed = lib.mkDefault {
        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              "ipv4.address" = "172.16.0.1/24";
              "ipv4.nat" = "true";
            };
          }
        ];
        profiles = [
          {
            name = "default";
            devices = {
              eth0 = {
                name = "eth0";
                network = "incusbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                size = "25GiB";
                type = "disk";
              };
            };
          }
        ];
        storage_pools = [
          {
            name = "default";
            driver = "dir";
            config = {
              source = "/var/lib/incus/storage-pools/default";
            };
          }
        ];
      };
    };

    users.users.leier.extraGroups = [ "incus-admin" ];
  };
}
