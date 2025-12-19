{ config, lib, ... }:
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
    ./graphical
  ];

  config = {
    nixdots.core = lib.mapAttrs (_: v: v // { enable = lib.mkDefault cfg.enableCore; }) cfg.core;
    nixdots.graphical.base = lib.mapAttrs (_: v: v // { enable = lib.mkDefault cfg.enableGraphicalSystem; }) cfg.graphical.base;
  };
}
