{
  flake.modules.nixos.plymouth = {
    boot = {
      plymouth.enable = true;

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
