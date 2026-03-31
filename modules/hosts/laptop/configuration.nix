{ self, ... }:
{
  configurations.nixos.laptop =
    { ... }:
    {
      imports = with self.modules; [
        profiles.nixos.minimal
      ];
    };
}
