{
  flake.modules.nixos.incus =
    { lib, ... }:
    {
      virtualisation.incus = {
        enable = true;
        ui.enable = lib.mkDefault false;
        agent.enable = lib.mkDefault true;
        preseed = lib.mkDefault {
          networks = [
            {
              name = "incusbr0";
              type = "bridge";
            }
          ];

          profiles = [
            {
              name = "default";
              config = {
                "limits.cpu" = "2";
                "limits.memory" = "4GiB";
              };
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

      networking.firewall.trustedInterfaces = [ "incusbr0" ];
    };
}
