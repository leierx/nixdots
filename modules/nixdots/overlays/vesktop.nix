{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.overlays.vesktopDiscordAlias;
in
{
  options.nixdots.overlays.vesktopDiscordAlias = {
    enable = lib.mkEnableOption "Enable Vesktop overlay that adds a Discord desktop entry and uses electron-bin";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (
        final: prev:
        let
          electronBin = prev.electron-bin;

          discordDesktopItem = final.makeDesktopItem {
            name = "discord";
            exec = "vesktop %U";
            icon = "discord";
            desktopName = "Discord";
            genericName = "All-in-one cross-platform voice and text chat for gamers";
            categories = [
              "Network"
              "InstantMessaging"
            ];
            mimeTypes = [ "x-scheme-handler/discord" ];
          };

          vesktopWithElectronBin = prev.vesktop.override {
            # don't build electron every rebuild
            electron = electronBin;
          };

          vesktopWithDiscordAlias = vesktopWithElectronBin.overrideAttrs (old: {
            desktopItems = (old.desktopItems or [ ]) ++ [ discordDesktopItem ];
          });
        in
        {
          vesktop = vesktopWithDiscordAlias;
        }
      )
    ];
    home-manager.users.${config.nixdots.core.primaryUser.username}.home.packages = [ pkgs.vesktop ];
  };
}
