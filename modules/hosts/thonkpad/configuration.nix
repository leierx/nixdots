{
  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { pkgs, ... }:
    {
      # stateful services key their data formats off this; never bump it with nixpkgs
      system.stateVersion = "26.05";

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
