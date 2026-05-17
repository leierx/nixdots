{
  modules.nixos.hosts.desktop =
    { pkgs, lib, ... }:
    {
      home-manager.sharedModules = [
        {
          # disable the home-manager systemd service; we manage kanshi via hyprland exec
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
                    position = "0,0";
                    status = "enable";
                    scale = 1.0;
                  }
                  {
                    criteria = "AOC Q27G2G4 0x000023BD";
                    mode = "2560x1440@144Hz";
                    position = "-2560,0";
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
