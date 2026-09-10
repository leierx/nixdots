{
  config,
  lib,
  inputs,
  ...
}:
let
  release = lib.trivial.release;

  defaults = {
    nixos = name: cfg: {
      networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" name));
      networking.hostName = lib.mkDefault name;
      nixpkgs.hostPlatform = lib.mkDefault cfg.platform;
      nixpkgs.config.allowUnfree = lib.mkDefault true;
      system.stateVersion = lib.mkDefault release;
    };
    darwin = name: cfg: {
      networking.hostName = lib.mkDefault name;
      nixpkgs.hostPlatform = lib.mkDefault cfg.platform;
      nixpkgs.config.allowUnfree = lib.mkDefault true;
      # nix-darwin takes an int here, not a release string
      system.stateVersion = lib.mkDefault 6;
    };
  };

  bundleModules = class: names: lib.concatMap (n: config.bundles.${n}.${class}) names;

  hmFor =
    class: user: homeModules:
    let
      homeDir = if class == "darwin" then "/Users/${user}" else "/home/${user}";
    in
    {
      imports = [
        (if class == "darwin" then
          inputs.home-manager.darwinModules.home-manager
        else
          inputs.home-manager.nixosModules.home-manager)
      ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules = [ { _module.args.theme = config.theme; } ];
        users.${user} = {
          imports = homeModules;
          home = {
            username = user;
            homeDirectory = homeDir;
            stateVersion = release;
          };
        };
      };
      # nix-darwin derives HM homeDirectory from the users.users entry
      users.users.${user}.home = lib.mkIf (class == "darwin") homeDir;
    };

  # exposes systems.<name>.user to feature modules via their flakeModules.<feature>.user option
  userOption =
    user:
    { options, lib, ... }:
    {
      config = lib.optionalAttrs (options ? flakeModules.user.name) {
        flakeModules.user.name = lib.mkDefault user;
      };
    };

  buildNixos =
    name: cfg:
    lib.nixosSystem {
      modules =
        [ (defaults.nixos name cfg) ]
        ++ bundleModules "nixos" cfg.bundles
        ++ cfg.modules
        ++ lib.optionals (cfg.user != null) [
          (hmFor "nixos" cfg.user (bundleModules "home" cfg.bundles))
          (userOption cfg.user)
        ];
    };

  buildDarwin =
    name: cfg:
    inputs.nix-darwin.lib.darwinSystem {
      modules =
        [ (defaults.darwin name cfg) ]
        ++ bundleModules "darwin" cfg.bundles
        ++ cfg.modules
        ++ lib.optional (cfg.user != null) (hmFor "darwin" cfg.user (bundleModules "home" cfg.bundles));
    };

  buildHome =
    name: cfg:
    assert lib.assertMsg (cfg.user != null) "systems.${name}: class \"home\" requires a user";
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = cfg.platform;
        config.allowUnfree = true;
      };
      modules =
        bundleModules "home" cfg.bundles
        ++ cfg.modules
        ++ [
          {
            home.username = cfg.user;
            home.homeDirectory = "/home/${cfg.user}";
            home.stateVersion = release;
          }
          { _module.args.theme = config.theme; }
        ];
    };

  byClass = class: lib.filterAttrs (_: c: c.class == class) config.systems;
in
{
  nixosConfigurations = lib.mapAttrs buildNixos (byClass "nixos");
  darwinConfigurations = lib.mapAttrs buildDarwin (byClass "darwin");
  homeConfigurations = lib.mapAttrs buildHome (byClass "home");
}
