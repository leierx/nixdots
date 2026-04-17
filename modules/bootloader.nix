{
  flake.modules.nixos.bootloader =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.flakeModules.bootloader;
    in
    {
      options.flakeModules.bootloader = {
        implementation = lib.mkOption {
          type = lib.types.enum [
            "grub"
            "systemdBoot"
          ];
          default = "grub";
          description = "Which bootloader implementation to use";
        };
      };

      config = {
        boot.tmp.cleanOnBoot = true;
        boot.loader = {
          efi.canTouchEfiVariables = true;
          timeout = 3;
          grub = lib.mkIf (cfg.implementation == "grub") {
            enable = true;
            efiSupport = true;
            devices = [ "nodev" ];
            configurationLimit = 5;
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
          systemd-boot = lib.mkIf (cfg.implementation == "systemdBoot") {
            enable = true;
            configurationLimit = 5;
          };
        };
      };
    };
}
