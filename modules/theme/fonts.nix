{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      # dejavu, liberation, noto-cjk-sans and noto-color-emoji come from here
      fonts.enableDefaultPackages = true;

      fonts.packages = with pkgs; [
        noto-fonts
        fira-code
        fira-code-symbols
        hack-font
        jetbrains-mono
        adwaita-fonts
        nerd-fonts.hack
        nerd-fonts.symbols-only
      ];
    };
}
