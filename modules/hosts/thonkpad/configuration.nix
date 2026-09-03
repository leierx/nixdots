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

      # wireguard
      networking.firewall.checkReversePath = false;

      environment.systemPackages = with pkgs; [
        mousepad
        spotify
        pavucontrol
        brave
        firefox-bin
        obsidian
        treefmt
        discord-canary
        kubectl
      ];
    };
}
