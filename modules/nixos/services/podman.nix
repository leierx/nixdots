{ pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings = {
      dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
  };

  # include compose by default
  environment.systemPackages = [ pkgs.podman-compose ];
}
