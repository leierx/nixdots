{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    # nixdots custom module
    "${inputs.self}/modules/nixdots"
  ];

  config = {
    # nixdots
    nixdots.base.bootloader.implementation = "systemd-boot";

    # VM guest helpers
    boot.initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
    ];

    services.qemuGuest.enable = true;
    virtualisation.incus.agent.enable = lib.mkDefault true;

    # networking
    networking.networkmanager.enable = true;

    # bloat removal
    documentation.nixos.enable = lib.mkForce false;

    # disk setup
    disko.devices = {
      disk = {
        sda = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00"; # EFI System
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "umask=0077"
                    "iocharset=utf8"
                    "noatime"
                  ];
                };
              };
              root = {
                type = "8300"; # Linux Filesystem
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
