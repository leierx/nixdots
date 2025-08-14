{ config, lib, ... }:
let
  # theme = config.dots.theme;
  cfg = config.dots.gui.apps.fuzzel;
in
{
  options.dots.gui.apps.fuzzel.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      ({
        wayland.windowManager.hyprland.settings.layerrule = ["dimaround, launcher"];

        programs.fuzzel = {
          enable = true;
          settings = {
            main = {
              font = "Hack:size=14";
              prompt = ''""'';
              line-height = 24;
              icon-theme = "Papirus-Dark";
              icons-enabled = true;
              fields = "name,generic,exec";
              match-counter = true;
              anchor = "center";
              lines = 10;
              width = 45;
              tabs = 0;
              horizontal-pad = 50;
              vertical-pad = 40;
              inner-pad = 10;
              image-size-ratio = 0;
              cache = "/dev/null";
            };

            colors = {
              background = "1C1C1Cff";
              selection = "2F2F2Fff";
              text = "eeeeeeff";
              counter = "eeeeeeff";
              input = "eeeeeeff";
              selection-text = "eeeeeeff";
              selection-match = "DC143Cff";
              match = "DC143Cff";
              prompt = "ffffffff";
              placeholder = "00000000";
              border = "000000ff";
            };

            border = {
              width = 1;
              radius = 20;
            };

            dmenu = {};
            key-bindings = {};
          };
        };
      })
    ];
  };
}
