{ pkgs, ... }:
{
  boot.loader = {
    efi.canTouchEfiVariables = true;

    timeout = 3;

    grub = {
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
  };
}
