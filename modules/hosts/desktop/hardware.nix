{
  flake.modules.nixos."nixosConfigurations/desktop" = {
    hardware = {
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;

      # udev uaccess rules so keymapp can flash the ZSA keyboard
      keyboard.zsa.enable = true;

      # Radeon RX 6700 XT
      graphics = {
        enable = true;
        enable32Bit = true; # required by Steam/Proton; explicit for clarity
      };
    };

    services = {
      fstrim.enable = true; # weekly TRIM for the NVMe
      fwupd.enable = true; # UEFI updates via LVFS
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 20;
    };

    # For incus/podman/qemu virtualization on Ryzen.
    boot.kernelModules = [ "kvm-amd" ];
  };
}
