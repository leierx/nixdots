{ config, ... }:
let
  dotEnabled = config.flake.meta.network.dot.enable;
in
{

  flake.modules.nixos.network = {
    config = {
      services.resolved = {
        enable = true;
        dnssec = "true";
        dnsovertls = if dotEnabled then "true" else "false";
      };

      networking = {
        nameservers =
          if dotEnabled then
            [
              "9.9.9.9#dns.quad9.net"
              "149.112.112.112#dns.quad9.net"
            ]
          else
            [
              "9.9.9.9"
              "149.112.112.112"
            ];
        enableIPv6 = false;

        firewall = {
          enable = true;
          allowPing = false;
        };

        nftables.enable = true;

        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          dhcp = "internal";
          ethernet.macAddress = "stable";
          wifi = {
            powersave = false;
            macAddress = "stable-ssid";
          };
          connectionConfig = {
            "ipv4.ignore-auto-dns" = true;
            "ipv6.ignore-auto-dns" = true;
          };
          settings.main.no-auto-default = "*";
        };
      };
    };
  };
}
