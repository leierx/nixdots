{
  flake.modules.nixos.systemdBoot = {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      timeout = 3;

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
  };
}
