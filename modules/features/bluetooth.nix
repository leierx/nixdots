{
  flake.modules.homeManager.bluetooth =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optional osConfig.hardware.bluetooth.enable pkgs.bluetui;
    };
}
