{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        firefox-bin
        obsidian
        discord-canary
      ];
    };
}
