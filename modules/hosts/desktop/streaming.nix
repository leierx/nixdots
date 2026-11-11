{
  flake.modules.nixos."nixosConfigurations/desktop".services.moonshine = {
    openFirewall = true;
    # allocated, not declared
    uid = 1000;
  };
}
