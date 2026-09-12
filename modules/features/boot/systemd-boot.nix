{
  flake.modules.nixos.systemd-boot = {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
  };
}
