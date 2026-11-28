{
  flake.modules.nixos."nixosConfigurations/thonkpad" = { pkgs, ... }: {
    hardware = {
      bluetooth = {
        enable = true;
        # the control centre powers it when wanted
        powerOnBoot = false;
      };
      cpu.intel.updateMicrocode = true;
      enableRedistributableFirmware = true;

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
      fwupd.enable = true;
      thermald.enable = true;
      # the bar's battery
      upower.enable = true;

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
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

    zramSwap = {
      enable = true;
      memoryPercent = 20;
    };
    # tuned for zram, not a disk: swapping is cheap, and read-ahead buys nothing
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
    };

    # the boot splash on i915 at the panel's mode from the start
    boot.initrd.kernelModules = [ "i915" ];
  };
}
