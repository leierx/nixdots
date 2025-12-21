{
  lib,
  config,
  ...
}:
let
  cfg = config.nixdots.programs.yazi;
in
{
  options.nixdots.programs.yazi = {
    enable = lib.mkEnableOption "Enable yazi";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      programs.yazi = {
        enable = true;

        flavors.kanagawa = ./kanagawa.yazi;
        theme.flavor.dark = "kanagawa";

        settings = {
          mgr = {
            ratio = [
              1
              3
              3
            ];
            sort_by = "natural";
            sort_sensitive = true;
            sort_reverse = false;
            sort_dir_first = true;
            sort_translit = true;
            linemode = "size";
            show_hidden = false;
            show_symlink = true;
            mouse_events = [ ];
          };

          preview = {
            tab_size = 2;
          };

          tasks = {
            suppress_preload = false;
            image_bound = [
              0
              0
            ];
          };

          input.cursor_blink = false;
        };

        keymap = { };
      };
    };
  };
}
