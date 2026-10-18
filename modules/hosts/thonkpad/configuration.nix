{
  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.treefmt ];

      # Brave finds Chromecasts over mDNS and takes replies on ephemeral ports.
      networking.firewall = {
        allowedUDPPorts = [ 5353 ];
        allowedUDPPortRanges = [
          {
            from = 32768;
            to = 60999;
          }
        ];
      };
    };
}
