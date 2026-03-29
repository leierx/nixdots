{ self, ... }:
{
  configurations.nixos.laptop =
    { ... }:
    {
      imports = [
        self.modules.profiles.base
      ];
    };
}
