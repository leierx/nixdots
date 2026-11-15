{
  flake.modules.homeManager."nixosConfigurations/desktop/home".hyprmoncfg.profiles = {
    default = [
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000023BD";
        mode = "2560x1440@143.91";
      }
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000021BD";
        mode = "2560x1440@143.91";
        x = 2560;
      }
    ];
    left-only = [
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000023BD";
        mode = "2560x1440@143.91";
      }
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000021BD";
        enabled = false;
      }
    ];
    right-only = [
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000023BD";
        enabled = false;
      }
      {
        make = "AOC";
        model = "Q27G2G4";
        serial = "0x000021BD";
        mode = "2560x1440@143.91";
      }
    ];
  };
}
