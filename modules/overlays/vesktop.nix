{
  modules.overlays.vesktop = {
    nixpkgs.overlays = [
      (
        final: prev:
        let
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
        in
        {
          vesktop = prev.vesktop.overrideAttrs (old: {
            desktopItems = (old.desktopItems or [ ]) ++ [ discordDesktopItem ];
          });
        }
      )
    ];
  };
}
