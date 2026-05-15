{ config, ... }:
{
  flake.modules.nixos.hosts.laptop =
    { pkgs, ... }:
    {
      imports = [
        config.flake.modules.nixos.graphical
      ];

      dot.bootloader.implementation = "systemdBoot";

      environment.systemPackages = with pkgs; [
        # xfce.mousepad
        # spotify
        # pavucontrol
        # brave
        # firefox-bin
        # obsidian
        # vesktop # discord client
        # opencode
        # treefmt
        # bitwarden-cli
      ];
    };
}
