{
  flake.modules.nixos.debloat =
    { pkgs, ... }:
    {
      # bloat removal
      documentation.nixos.enable = false;
      networking.dhcpcd.enable = false;
      services.xserver.excludePackages = [ pkgs.xterm ];
    };
}
