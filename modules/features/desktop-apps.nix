{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        mousepad
        spotify
        pwvucontrol
        firefox-bin
        obsidian
        discord-canary
      ];
    };
}
