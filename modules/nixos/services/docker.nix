{ lib, pkgs, ... }:
{
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # disable rootless docker enabled on boot.
  systemd.user.services.docker.wantedBy = lib.mkForce [];

  # include compose by default
  environment.systemPackages = [ pkgs.docker-compose ];
}
