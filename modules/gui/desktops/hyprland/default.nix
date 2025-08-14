{ config, lib, pkgs, flakeInputs, ... }:
let
  cfg = config.dots.gui.hyprland;
in
{
  options.dots.gui.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dots.gui.enable;
    };
    hyprpaper.enable = lib.mkOption { type = lib.types.bool; default = cfg.enable; };
    hyprlock.enable = lib.mkOption { type = lib.types.bool; default = cfg.enable; };
    hypridle.enable = lib.mkOption { type = lib.types.bool; default = cfg.enable; };
  };

  imports = [
    ./configuration
    ./hypridle
    ./hyprlock
    ./hyprpaper
  ];

  config = lib.mkIf cfg.enable {
    # Install
    programs.hyprland.enable = true;
    programs.hyprland.package = flakeInputs.hyprland.packages.${pkgs.system}.hyprland;
    programs.hyprland.portalPackage = flakeInputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

    # Default application suite
    services.gvfs.enable = true; # nautilus functionallity
    services.dbus.packages = [ pkgs.sushi ]; # nautilus functionallity

    environment.systemPackages = with pkgs; [
      nautilus # file explorer
      sushi # file explorer addon
      file-roller # file explorer addon
      grimblast # screenshot utility
      wl-clipboard # wayland clipboard utility
      firefox-bin # browser of choice currently
    ] ++ [
      flakeInputs.ags.packages.${pkgs.system}.agsFull # ags/astal dev tools
    ];

    dots.gui.apps.footTerminal.enable = true; # terminal of choice
    dots.gui.apps.fuzzel.enable = true; # application launcher + dmenu

    home-manager.sharedModules = [
      ({
        wayland.windowManager.hyprland.settings = {
          "$terminal" = "foot";
          "$TERMINAL" = "foot";
          "$TERM" = "foot"; 
          "$browser" = "firefox";
          "$applicationLauncher" = "fuzzel";
        };
      })
    ];
  };
}
