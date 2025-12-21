{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.graphical.base.audio;
in
{
  options.nixdots.graphical.base.audio = {
    enable = lib.mkEnableOption "Enable base audio (PipeWire + rtkit)";
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
