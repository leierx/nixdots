{ config, lib, ... }:
{
  flake.modules.nixos."nixosConfigurations/desktop" = {
    services.moonshine = {
      openFirewall = true;
      # allocated, not declared
      uid = 1000;
    };

    # a boot entry: gamescope + Steam on a forced 4K connector, streamed by Sunshine
    specialisation.game-mode.configuration = {
      imports = [ config.flake.modules.nixos.game-mode ];
      gameMode.output = "DP-3";
      # both serve the Moonlight ports
      services.moonshine.enable = lib.mkForce false;
    };
  };
}
