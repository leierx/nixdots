{ lib, config, ... }:
let
  cfg = config.nixdots.core.network;

  quad9Plain = [
    "9.9.9.9"
    "149.112.112.112"
  ];

  quad9Dot = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];
in
{
  options.nixdots.core.network = {
    enable = lib.mkEnableOption "Enable networking";

    dot.enable = lib.mkEnableOption "Enable DoT via systemd-resolved";

    implementation = lib.mkOption {
      type = lib.types.enum [
        "networkmanager"
        "networkd"
      ];
      default = "networkmanager";
      description = "Which network managment implementation to use";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # COMMON CONFIG - resolved+networking
      {
        services.resolved = {
          enable = true;
          dnssec = "true";
          dnsovertls = if cfg.dot.enable then "true" else "false";
        };

        networking = {
          nameservers = if cfg.dot.enable then quad9Dot else quad9Plain;

          enableIPv6 = false; # all my homies use ipv4

          firewall = {
            enable = true;
            allowPing = false;
            logRefusedConnections = true;
            # allowedTCPPorts = [ 80 443 ];
          };
        };
      }

      # NetworkManager
      (lib.mkIf (cfg.implementation == "networkmanager") {
        networking.networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          dhcp = "internal";
          ethernet.macAddress = "stable";

          wifi = {
            powersave = false;
            macAddress = "stable-ssid";
          };

          settings = {
            main = {
              no-auto-default = "*"; # do not automatically create connection profiles.
            };
          };
        };
      })
    ]
  );
}
