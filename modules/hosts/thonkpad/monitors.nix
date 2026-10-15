{
  flake.modules.homeManager."nixosConfigurations/thonkpad/home" = {
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

  };
}
