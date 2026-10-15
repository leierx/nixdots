{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        obsidian
        discord-canary
      ];
    };
}
