{
  hosts.thonkpad.modules = [
    ({ pkgs, lib, ... }: {
      home-manager.sharedModules = [
        {
          systemd.user.services.kanshi = lib.mkForce { };

          services.kanshi = {
            enable = true;
            settings = [
              {
                profile.name = "default";
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
            on = [
              {
                _args = [
                  "hyprland.start"
                  (lib.generators.mkLuaInline ''function() hl.exec_cmd("${lib.getExe pkgs.kanshi}") end'')
                ];
              }
              {
                _args = [
                  "config.reloaded"
                  (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.kanshi}/bin/kanshictl reload") end'')
                ];
              }
            ];
          };
        }
      ];
    })
  ];
}
