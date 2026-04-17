{ inputs, ... }:
{
  flake.modules.nixos.hyprland =
    { pkgs, lib, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

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

      home-manager.sharedModules = [ inputs.self.modules.homeManager.hyprland ];
    };

  flake.modules.homeManager.hyprland =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        inputs.self.modules.homeManager.wezterm
        inputs.self.modules.homeManager.fuzzel
      ];

      home.packages = [ pkgs.wl-clipboard ];

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        package = osConfig.programs.hyprland.package;
        settings = {
          "$mod" = "SUPER";
          "$terminal" = "wezterm";
          "$applicationLauncher" = "fuzzel";
          "$screenshot" = "${lib.getExe pkgs.hyprshot} --mode region --freeze --silent --clipboard-only";
        };
      };
    };
}
