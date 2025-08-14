{ config, lib, pkgs, ... }:
let
  cfg = config.dots.gui.fonts;
in
{
  options.dots.gui.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dots.gui.enable;
    };

    defaultFonts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        noto-fonts-color-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        hack-font
        jetbrains-mono
        adwaita-fonts
      ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.enableDefaultPackages = true;
    fonts.packages = cfg.defaultFonts;
  };
}
