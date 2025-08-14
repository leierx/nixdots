{ config, lib, ... }:
let
  cfg = config.dots.core.network;
in
{
  options.dots.core.network = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "networking configuration";
    };
    dnscryptProxy2.enable = lib.mkEnableOption "DNSCrypt-Proxy v2 for encrypted DNS resolution";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking = {
        networkmanager = {
          enable = true;
          dhcp = "internal";
          dns = "default";
          ethernet.macAddress = "stable";
          logLevel = "WARN";

          wifi = {
            backend = "wpa_supplicant";
            powersave = false;
            macAddress = "stable";
          };

          settings = {
            main = {
              no-auto-default = "*"; # do not automatically create connection profiles.
            };
          };
        };

        enableIPv6 = false; # all my homies use ipv4

        firewall = {
          enable = true;
          allowPing = false;
          logRefusedConnections = true;
          # allowedTCPPorts = [ 80 443 ];
        };
      };
    }

    (lib.mkIf cfg.dnscryptProxy2.enable {
      services.dnscrypt-proxy2 = {
        enable = true;
        upstreamDefaults = false;
        settings = {
          listen_addresses = [ "127.0.0.1:53" ];
          ipv6_servers = false;
          require_dnssec = true;
          cache = true;
          log_level = 2;

          # might be useful for debugging
          #query_log.file = "/dev/stdout";

          server_names = [
            "quad9-dnscrypt-ip4-nofilter-pri"
            "quad9-dnscrypt-ip4-nofilter-alt"
          ];

          sources."quad9-resolvers" = {
            urls = [
              "https://quad9.net/dnscrypt/quad9-resolvers.md"
              "https://raw.githubusercontent.com/Quad9DNS/dnscrypt-settings/main/dnscrypt/quad9-resolvers.md"
            ];
            minisign_key = "RWTp2E4t64BrL651lEiDLNon+DqzPG4jhZ97pfdNkcq1VDdocLKvl5FW";
            cache_file = "/var/cache/dnscrypt-proxy/quad9-resolvers.md";
            refresh_delay = 72;
            prefix = "quad9-";
          };
        };
      };
    })
  ]);
}
