{ config, ... }:
let
  implementation = config.flake.meta.bootloader.implementation;
in
{
  flake.modules.nixos.bootloader =
    { lib, pkgs, ... }:
    {
      config = {
        boot.tmp.cleanOnBoot = true;
        boot.loader = lib.mkMerge [
          {
            efi.canTouchEfiVariables = true;
            timeout = 3;
          }
          (lib.mkIf (implementation == "systemd-boot") {
            systemd-boot = {
              enable = true;
              configurationLimit = 5;
            };
          })
          (lib.mkIf (implementation == "grub") {
            grub = {
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
          })
        ];
      };
    };
}
