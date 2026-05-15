{
  flake.modules.nixos.network = {
    services.resolved = {
      enable = true;
      dnssec = "true";
      dnsovertls = "true";
    };

    networking = {
      nameservers = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
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
}
