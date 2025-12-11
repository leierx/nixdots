{
  networking = {
    networkmanager = {
      enable = true;
      dhcp = "internal";
      dns = "default";
      ethernet.macAddress = "stable";
      logLevel = "WARN";

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

    enableIPv6 = false; # all my homies use ipv4

    firewall = {
      enable = true;
      allowPing = false;
      logRefusedConnections = true;
      # allowedTCPPorts = [ 80 443 ];
    };
  };
}
