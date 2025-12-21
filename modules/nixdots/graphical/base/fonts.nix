{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.graphical.base.fonts;
in
{
  options.nixdots.graphical.base.fonts = {
    enable = lib.mkEnableOption "Enable base system fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts.enableDefaultPackages = true;

    fonts.packages =
      (with pkgs; [
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        hack-font
        jetbrains-mono
        adwaita-fonts
      ])
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };
}
