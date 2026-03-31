{ pkgs, ... }:
{
  flake.modules.nixos.debloat = {
    documentation.nixos.enable = false;
    networking.dhcpcd.enable = false;
    services.xserver.excludePackages = [ pkgs.xterm ];

    environment.systemPackages = with pkgs; [
      jq
      fzf
      fastfetch
      tree
    ];
  };
}
