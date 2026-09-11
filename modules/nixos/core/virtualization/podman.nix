{
  flake.modules.nixos.podman =
    { pkgs, ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      networking.firewall.interfaces.podman0 = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
      };

      environment.systemPackages = with pkgs; [ podman-compose ];
    };
}
