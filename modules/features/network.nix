{
  flake.modules.nixos.network = {
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNSOverTLS = "true";
        Domains = "~."; # fallback route only; a link with its own DNS servers is still queried
        FallbackDNS = ""; # never fall back to built-in plaintext servers
      };
    };

    networking = {
      nameservers = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];

      firewall = {
        allowPing = false;
        # strict breaks WireGuard full tunnels
        checkReversePath = "loose";
      };

      nftables.enable = true;

      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
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
}
