{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.services.podman;
in
{
  options.nixdots.services.podman = {
    enable = lib.mkEnableOption "Enable Podman";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    # include compose by default
    environment.systemPackages = with pkgs; [ podman-compose ];
  };
}
