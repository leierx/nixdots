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
                    mode = "2560x1440@143.91Hz";
                    position = "2560,0";
                    scale = 1.0;
                  }
                  {
                    criteria = "AOC Q27G2G4 0x000023BD";
                    mode = "2560x1440@143.91Hz";
                    position = "0,0";
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
