{ self, ... }:
{
  flake.modules.nixos.cursor =
    { ... }:
    {
      config = {
        home-manager.sharedModules = [ self.modules.homeManager.cursor ];
      };
    };

  flake.modules.homeManager.cursor =
    { osConfig, pkgs, ... }:
    {
      home.pointerCursor = {
        name = "Adwaita";
        size = osConfig.flake.meta.cursor.size;
        package = pkgs.adwaita-icon-theme;
        x11 = {
          enable = true;
          defaultCursor = "left_ptr";
        };
        gtk.enable = true;
      };

      home.sessionVariables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = builtins.toString osConfig.flake.meta.cursor.size;
      };
    };
}
