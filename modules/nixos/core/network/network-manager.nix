{
  networking = {
    networkmanager = {
      enable = true;
      dhcp = "internal";
      dns = "default";
      ethernet.macAddress = "stable";
      logLevel = "WARN";

      wifi = {
        backend = "iwd";
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
