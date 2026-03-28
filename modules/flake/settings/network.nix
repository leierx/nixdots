{ lib, ... }:
{
  options.flake.settings.network = with lib; {
    dot.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };
}
