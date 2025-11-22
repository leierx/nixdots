{ pkgs, ... }:
{
  services.locate = {
    enable = true;
    package = pkgs.plocate;
    interval = "daily";
    output = "/var/cache/locatedb";
  };

  # hack to avoid running straigh after booting the system
  systemd.timers.update-locatedb.timerConfig.OnBootSec = "30m";
}
