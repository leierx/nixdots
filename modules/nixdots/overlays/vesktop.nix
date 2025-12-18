{ pkgs, ... }:
{
  nixpkgs.overlays = [
    # dont manually build electron 35 every rebuild
    (final: prev: {
      vesktop = prev.vesktop.override {
        electron = prev.electron-bin;
      };
    })

    # discord alias
    (final: prev: {
      vesktop = prev.vesktop.overrideAttrs (old: {
        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "discord";
            exec = "vesktop %U";
            icon = "discord";
            desktopName = "Discord";
            genericName = "All-in-one cross-platform voice and text chat for gamers";
            categories = [ "Network" "InstantMessaging" ];
            mimeTypes = [ "x-scheme-handler/discord" ];
          })
        ];
      });
    })
  ];
}
