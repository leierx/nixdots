{
  configurations.nixos.laptop =
    { pkgs, ... }:
    {
      hardware = {
        bluetooth.enable = true;
        cpu.intel.updateMicrocode = true;
        enableRedistributableFirmware = true;
        trackpoint.enable = false;

        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            intel-media-driver
            vpl-gpu-rt
          ];
          extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
        };
      };

      services = {
        fprintd.enable = true; # fingerprint reader. See: https://github.com/NixOS/nixpkgs/issues/171136
        fstrim.enable = true; # SSD trimming
        fwupd.enable = true; # firmware update, recommended on thinkpads
        # hardware.bolt.enable = true; # thunderbolt dock
        power-profiles-daemon.enable = false; # Gnome/KDE default, conflicts with TLP
        thermald.enable = true; # Thermal management
        upower.enable = true; # Battery monitoring

        tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            #
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
            #
            CPU_MIN_PERF_ON_AC = 0;
            CPU_MAX_PERF_ON_AC = 100;
            CPU_MIN_PERF_ON_BAT = 0;
            CPU_MAX_PERF_ON_BAT = 35;
            # battery longevity
            START_CHARGE_THRESH_BAT0 = 40;
            STOP_CHARGE_THRESH_BAT0 = 80;
          };
        };
      };
    };
}
