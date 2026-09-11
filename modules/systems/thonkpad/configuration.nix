{ config, ... }:
{
  hosts.thonkpad = {
    user = "leier";
    bundles = [
      "minimal"
      "graphical"
    ];
    modules = [
      config.flake.modules.nixos.gaming
      ({ pkgs, ... }: {
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
      })
    ];
  };
}
