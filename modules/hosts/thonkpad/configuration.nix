{
  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.treefmt ];
    };
}
