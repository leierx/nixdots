{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        unstable.brave-origin
        firefox-bin
        obsidian
        discord-canary
      ];
    };
}
