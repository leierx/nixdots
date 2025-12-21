{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.nixdots;
in
{
  options.nixdots = {
    enableCore = lib.mkEnableOption "enable core modules";
    enableGraphicalSystem = lib.mkEnableOption "enable graphical system (sound, fonts, display-manager, etc.)";
  };

  imports = [
    ./core
    ./overlays
    ./services
    ./graphical
    ./programs
  ];

  config = {
    nixdots.core = lib.mapAttrs (_: _: { enable = lib.mkDefault cfg.enableCore; }) options.nixdots.core;
    nixdots.graphical.base = lib.mapAttrs (_: _: { enable = lib.mkDefault cfg.enableGraphicalSystem; }) options.nixdots.graphical.base;
  };
}
