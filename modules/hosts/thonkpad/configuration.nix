{ config, ... }:
{
  modules.nixos.hosts.thonkpad =
    { pkgs, ... }:
    {
      imports = [
        config.modules.nixos.profiles.minimal
        config.modules.nixos.profiles.graphical
        config.modules.nixos.gaming
      ];

      environment.systemPackages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        obsidian
        vesktop
        opencode
        treefmt
        bitwarden-cli
      ];
    };
}
