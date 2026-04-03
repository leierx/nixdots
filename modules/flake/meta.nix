{ config, lib, ... }:
{
  options.flake.meta = with lib; {
    bootloader.implementation = mkOption {
      type = types.enum [
        "systemd-boot"
        "grub"
      ];
      default = "grub";
    };

    cursor.size = mkOption {
      type = types.int;
      default = 24;
    };

    displayManager.implementation = mkOption {
      type = types.enum [
        "gdm"
        "ly"
      ];
      default = "ly";
    };

    network.dot.enable = mkOption {
      type = types.bool;
      default = true;
    };

    security.wheelNeedsPassword = mkOption {
      type = types.boolean;
      default = false;
    };

    user = {
      username = mkOption {
        type = types.singleLineStr;
        default = "leier";
      };

      fullName = mkOption {
        type = types.singleLineStr;
        default = "Lars Smith Eier";
      };

      email = mkOption {
        type = types.singleLineStr;
        default = "larssmitheier@protonmail.com";
      };

      homeDirectory = mkOption {
        type = types.singleLineStr;
        default = "/home/${config.flake.meta.user.username}";
      };
    };
  };
}
