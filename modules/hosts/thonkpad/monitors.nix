{
  modules.nixos.hosts.thonkpad =
    { pkgs, lib, ... }:
    {
      home-manager.sharedModules = [
        {
          systemd.user.services.kanshi = lib.mkForce { };

          services.kanshi = {
            enable = true;
            settings = [
              {
                profile.name = "laptop";
                profile.outputs = [
                  {
                    criteria = "eDP-1";
                    mode = "1920x1200@60Hz";
                    position = "0,0";
                    status = "enable";
                    scale = 1.0;
                  }
                ];
              }
            ];
          };

          wayland.windowManager.hyprland.settings = {
            exec-once = [ "${lib.getExe pkgs.kanshi}" ];
            exec = [ "${pkgs.kanshi}/bin/kanshictl reload" ];
          };
        }
      ];
    };
}
