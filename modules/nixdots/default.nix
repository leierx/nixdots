{ config, lib, ... }:
{
  options.nixdots.enableCore = lib.mkEnableOption "enable core modules";

  imports = [
    ./core
  ];

  # auto-enable *all* nixdots.core.<name>.enable
  config.nixdots.core = lib.mapAttrs (_name: _value: {
    enable = lib.mkDefault config.nixdots.enableCore;
  }) config.nixdots.core;
}
