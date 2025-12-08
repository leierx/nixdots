{
  boot = {
    plymouth.enable = true;

    # hide kernel + systemd noise
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelParams = [
      "quiet" # less kernel output
      "splash" # hint for plymouth
      "systemd.show_status=false" # quiet systemd during boot
      "rd.systemd.show_status=false" # quiet initrd systemd during boot
    ];
  };
}
