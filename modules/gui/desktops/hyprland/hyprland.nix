{ config, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.hyprland =
    { pkgs, lib, ... }:
    {
      programs.hyprland.enable = true;

      nix.settings = {
        substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
        trusted-substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
        trusted-public-keys = lib.mkAfter [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.sharedModules = [ outerConfig.modules.homeManager.hyprland ];
    };

  modules.homeManager.hyprland =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        outerConfig.modules.homeManager.wezterm
        outerConfig.modules.homeManager.rofi
      ];

      home.packages = [ pkgs.wl-clipboard ];

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        package = null;
        portalPackage = null;
        systemd.variables = [ "--all" ];
        settings = {
          "$mod" = "SUPER";
          "$terminal" = "wezterm";
          "$applicationLauncher" = "rofi -modes drun -show drun";
          "$screenshot" = "${lib.getExe pkgs.hyprshot} --mode region --freeze --silent --clipboard-only";
          # autostart
          exec-once = lib.optional osConfig.networking.networkmanager.enable "${lib.getExe pkgs.networkmanagerapplet}";
        };
      };
    };
}
