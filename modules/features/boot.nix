# Booting. The default is GRUB on EFI, which is what every machine here
# uses; `systemd-boot` is the alternative and forces GRUB back off, so a
# host can import it on top of `base` without touching the profile.
{
  flake.modules.nixos.boot =
    { pkgs, ... }:
    {
      boot.tmp.cleanOnBoot = true;

      boot.loader = {
        timeout = 3;

        efi.canTouchEfiVariables = true;

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
      };
    };

  flake.modules.nixos.systemd-boot =
    { lib, ... }:
    {
      boot.loader.grub.enable = lib.mkForce false;

      boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
}
