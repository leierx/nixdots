{
  inputs,
  lib,
  ...
}:
{
  imports = [
    # nixdots custom module
    "${inputs.self}/modules/nixdots"
    # extra config files
    ./disko.nix
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

    # keep config minimal
    documentation.nixos.enable = lib.mkForce false;
  };
}
