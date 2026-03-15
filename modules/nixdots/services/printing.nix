{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.services.printing;
in
{
  options.nixdots.services.printing = {
    enable = lib.mkEnableOption "nixdots.services.printing";
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
