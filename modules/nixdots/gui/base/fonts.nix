{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.gui.base.fonts;
in
{
  options.nixdots.gui.base.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixdots.gui.enableBase;
      description = "Whether to enable nixdots.gui.base.fonts";
    };
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
