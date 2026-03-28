{ config, ... }:
{
  flake.modules.nixos.networkManager =
    let
      quad9Plain = [
        "9.9.9.9"
        "149.112.112.112"
      ];
      quad9Dot = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];

      dotEnabled = config.flake.settings.network.dot.enable;
    in
    {
      services.resolved = {
        enable = true;
        dnssec = "true";
        dnsovertls = if dotEnabled then "true" else "false";
      };

      networking = {
        nameservers = if dotEnabled then quad9Dot else quad9Plain;

        enableIPv6 = false;

        firewall = {
          enable = true;
          allowPing = false;
          # logRefusedConnections = true;
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

          settings.main = {
            no-auto-default = "*";
          };
        };
      };
    };
}
