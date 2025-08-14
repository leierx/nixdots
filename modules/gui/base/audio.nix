{ config, lib, ... }:
let
  cfg = config.dots.gui.audio;
in
{
  options.dots.gui.audio.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.dots.gui.enable;
  };

  config = lib.mkIf cfg.enable {
    # Enable sound with pipewire.
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    # Realtime Policy and Watchdog Daemon. Many programs depends on it like pipewire
    security.rtkit.enable = true;
  };
}
