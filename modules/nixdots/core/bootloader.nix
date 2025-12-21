{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.core.bootloader;
in
{
  options.nixdots.core.bootloader = {
    enable = lib.mkEnableOption "Enable bootloader";

    implementation = lib.mkOption {
      type = lib.types.enum [
        "systemd-boot"
        "grub"
      ];
      default = "grub";
      description = "Which bootloader implementation to use";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # COMMON CONFIG
      {
        boot.loader = {
          efi.canTouchEfiVariables = true;
          timeout = 3;
        };
      }

      # SYSTEMD-BOOT
      (lib.mkIf (cfg.implementation == "systemd-boot") {
        boot.loader.systemd-boot = {
          enable = true;
          netbootxyz.enable = true; # looks awesome
          configurationLimit = 5;
        };
      })

      # GRUB
      (lib.mkIf (cfg.implementation == "grub") {
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          devices = [ "nodev" ];

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
      })
    ]
  );
}
