{ lib, ... }:
{
  options.flake.settings.security = with lib; {
    wheelNeedsPassword = mkOption {
      type = types.boolean;
      default = false;
    };
  };
}
