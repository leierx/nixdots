{
  modules.nixos.hosts.desktop =
    { pkgs, lib, ... }:
    {
      home-manager.sharedModules = [
        {
          systemd.user.services.kanshi = lib.mkForce { };

          services.kanshi = {
            enable = true;
            settings = [
              {
                profile.name = "main";
                profile.outputs = [
                  {
                    criteria = "AOC Q27G2G4 0x000021BD";
                    mode = "2560x1440@144Hz";
                    position = "2560,0";
                    scale = 1.0;
                  }
                  {
                    criteria = "AOC Q27G2G4 0x000023BD";
                    mode = "2560x1440@144Hz";
                    position = "0,0";
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
            ];
            exec_cmd = "${pkgs.kanshi}/bin/kanshictl reload";
          };
        }
      ];
    };
}
