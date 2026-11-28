{
  flake.modules.nixos."nixosConfigurations/desktop" = {
    hardware = {
      # the boot splash on amdgpu at the panel's mode from the start
      amdgpu.initrd.enable = true;
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;

      # udev uaccess rules so keymapp can flash the ZSA keyboard
      keyboard.zsa.enable = true;

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    services.fwupd.enable = true;

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
  };
}
