{
  flake.modules.homeManager.hyprland =
    { config, ... }:
    {
      programs.swappy = {
        enable = true;
        settings.Default = {
          save_dir = "${config.xdg.userDirs.pictures}/screenshots";
          save_filename_format = "%Y%m%d-%H%M%S.png";
          show_panel = true;
          paint_mode = "rectangle";
          early_exit = true;
        };
      };
    };
}
