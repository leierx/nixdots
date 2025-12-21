{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.services.locate;
in
{
  options.nixdots.services.locate = {
    enable = lib.mkEnableOption "Enable locate command";
  };

  config = lib.mkIf cfg.enable {
    services.locate = {
      enable = true;
      interval = "daily";
      output = "/var/cache/locatedb";
    };

    # avoid running immediately after boot
    systemd.timers.update-locatedb.timerConfig.OnBootSec = "10m";
  };
}
