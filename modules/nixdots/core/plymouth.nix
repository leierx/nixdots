{ lib, config, ... }:
let
  cfg = config.nixdots.core.plymouth;
in
{
  options.nixdots.core.plymouth = {
    enable = lib.mkEnableOption "Enable plymouth";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      plymouth.enable = true;

      # hide kernel + systemd noise
      consoleLogLevel = 0;
      initrd.verbose = false;

      kernelParams = [
        "quiet"
        "splash"
        "systemd.show_status=false"
        "rd.systemd.show_status=false"
      ];
    };
  };
}
