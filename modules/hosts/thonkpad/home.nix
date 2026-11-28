root: {
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" =
    { lib, osConfig, ... }:
    {
      imports = [ root.config.flake.modules.homeManager.homelab ];

      # an idle laptop sleeps rather than drains its battery
      services.hypridle.settings.listener = [
        {
          timeout = 900;
          on-timeout = "${lib.getExe' osConfig.systemd.package "systemctl"} suspend";
        }
      ];

      wayland.windowManager.hyprland.settings = {
        gesture = [
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
        ];
        # past the last a swipe would make a workspace outside the monitor's hyprsplit range
        config.gestures.workspace_swipe_create_new = false;
      };
    };
}
