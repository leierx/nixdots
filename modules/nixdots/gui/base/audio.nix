{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.gui.base.audio;
in
{
  options.nixdots.gui.base.audio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.audio";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sound with PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    # Realtime Policy and Watchdog Daemon (needed by PipeWire and others)
    security.rtkit.enable = true;
  };
}
