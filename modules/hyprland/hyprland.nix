{
  config,
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.hyprland =
    { pkgs, lib, ... }:
    {
      # Hyprland install
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };
      # cache
      nix.settings = {
        substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
        trusted-substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
        trusted-public-keys = lib.mkAfter [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      # file-manager
      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.users.${config.flake.settings.user.username}.imports = [ self.modules.homeManager.hyprland ];
    };

  flake.modules.homeManager.hyprland =
    { pkgs, osConfig, ... }:
    {
      imports = [
        self.modules.homeManager.wezterm # terminal of choice
        self.modules.homeManager.fuzzel # app launcher
      ];

      # extra packages
      home.packages = [ pkgs.wl-clipboard ];

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        package = osConfig.programs.hyprland.package;
        settings = {
          "$mod" = "SUPER";
          "$terminal" = "wezterm";
          "$applicationLauncher" = "fuzzel";
          "$screenshot" = "${pkgs.hyprshot}/bin/hyprshot --mode region --freeze --silent --clipboard-only";
        };
      };
    };
}
