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

      # the podman module opens UDP 53 alone
      networking.firewall.interfaces.podman0.allowedTCPPorts = [ 53 ];

      environment.systemPackages = with pkgs; [ podman-compose ];
    };
}
