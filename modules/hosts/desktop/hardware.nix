{
  flake.modules.nixos."nixosConfigurations/desktop" = {
    hardware = {
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;

      # udev uaccess rules so keymapp can flash the ZSA keyboard
      keyboard.zsa.enable = true;

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    services = {
      fstrim.enable = true;
      fwupd.enable = true;
    };

    zramSwap = {
      enable = true;
      memoryPercent = 20;
    };

    # for incus/podman/qemu VMs
    boot.kernelModules = [ "kvm-amd" ];
  };
}
