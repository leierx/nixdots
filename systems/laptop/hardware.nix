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

  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "thinkpad_acpi" "iwlwifi" ]; # everything else should be built in or autoloaded

  services.xserver.videoDrivers = [ "intel" ];
  services.libinput.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  powerManagement.cpuFreqGovernor = "performance";

  networking.networkmanager.wifi.backend = lib.mkForce "wpa_supplicant";

  hardware.bluetooth.enable = true;
  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = true;
  hardware.cpu.intel.updateMicrocode = true; # Intel CPU
  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
