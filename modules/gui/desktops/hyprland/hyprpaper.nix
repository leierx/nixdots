{
  modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      services.hyprpaper = {
        enable = true;
        settings = {
          ipc = false;
          splash = false;
          preload = ./assets/wallpaper.png;
          wallpaper = ",${./assets/wallpaper.png}";
        };
      };

      # disable the home-manager systemd service
      systemd.user.services.hyprpaper = lib.mkForce { };

      wayland.windowManager.hyprland.settings.exec-once = [ "${lib.getExe pkgs.hyprpaper}" ];
    };
}
