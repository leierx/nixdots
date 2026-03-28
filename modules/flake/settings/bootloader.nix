{ lib, ... }:
{
  options.flake.settings.bootloader = with lib; {
    implementation = mkOption {
      type = types.enum [
        "systemd-boot"
        "grub"
      ];
      default = "grub";
    };
  };
}
