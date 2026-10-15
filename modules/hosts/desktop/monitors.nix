{
  flake.modules.homeManager."nixosConfigurations/desktop/home" = {
    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "default";
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
        {
          profile.name = "left";
          profile.outputs = [
            {
              criteria = "AOC Q27G2G4 0x000023BD";
              mode = "2560x1440@143.91Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "AOC Q27G2G4 0x000021BD";
              status = "disable";
            }
          ];
        }
      ];
    };

  };
}
