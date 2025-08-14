{ pkgs, lib, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  swapDevices = lib.mkForce [];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "btusb" "usb_storage" "sd_mod" ]; # basicly kernel modules needed to mount/boot
  boot.kernelModules = [ "amdgpu" "kvm-amd" ]; # AMD GPU + kvm stuff

  services.xserver.videoDrivers = [ "amdgpu" ];

  powerManagement.cpuFreqGovernor = "performance";

  hardware.cpu.amd.updateMicrocode = true; # AMD CPU
  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.amdvlk = {
    enable = true;
    support32Bit.enable = true;
  };
}
