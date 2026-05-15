{
  flake.modules.nixos.sound = {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    security.rtkit.enable = true;
  };
}
