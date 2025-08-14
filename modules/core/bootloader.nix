{ config, lib, pkgs, ... }:
let
  cfg = config.dots.core.bootLoader;
in
{
  options.dots.core.bootLoader = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "the boot loader configuration (GRUB or systemd-boot)";
    };

    implementation = lib.mkOption {
      type = lib.types.enum [ "grub" "systemd-boot" ];
      default = "grub";
      description = "Boot loader implementation to configure for the system.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Generic configuration (applies to any boot-loader)
    {
      boot.tmp.cleanOnBoot = true;
      boot.loader.efi.canTouchEfiVariables = true;
    }

    # GRUB configuration
    (lib.mkIf (cfg.implementation == "grub") {
      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";

        # GRUB theme
        theme = pkgs.stdenv.mkDerivation {
          name = "grub_theme";
          src = pkgs.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "c96f868e75707ea2b2eb2869a3d67bd9c151cee6";
            hash = "sha256-QHqsQUEYxa04je9r4FbOJn2FqRlTdBLyvwZXw9JxWlQ=";
          };
          installPhase = ''
            mkdir -p $out
            tar -xf themes/nixos.tar -C $out
          '';
        };
      };

      boot.loader.timeout = 5;
    })

    # Systemd-boot configuration
    (lib.mkIf (cfg.implementation == "systemd-boot") {
      boot.loader = {
        grub.enable = false;

        systemd-boot = {
          enable = true;
          editor = true;
        };

        timeout = 3;
      };
    })
  ]);
}
