{ config, ... }:
{
  modules.nixos.hosts.thonkpad =
    { pkgs, ... }:
    {
      imports = [
        config.modules.nixos.profiles.minimal
        config.modules.nixos.profiles.graphical
      ];

      environment.systemPackages =
        (with pkgs; [
          mousepad
          spotify
          pavucontrol
          brave
          firefox-bin
          obsidian
          opencode
          treefmt
          bitwarden-cli
        ])
        ++ (with pkgs.unstable; [ discord-canary ]);
    };
}
