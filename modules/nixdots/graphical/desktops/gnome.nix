{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.graphical.desktops.gnome;
in
{
  options.nixdots.graphical.desktops.gnome = {
    enable = lib.mkEnableOption "Enable GNOME desktop (NixOS + Home Manager dconf)";
  };

  config = lib.mkIf cfg.enable {
    # terminal emulator of choice
    nixdots.programs.wezterm.enable = true;

    # Install
    services.desktopManager.gnome.enable = true;

    # Disable GNOME bloat
    services.gnome.core-apps.enable = false;
    services.gnome.core-developer-tools.enable = false;
    services.gnome.gnome-online-accounts.enable = false;
    services.gnome.games.enable = false;
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs
    ];

    # GNOME settings via dconf
    home-manager.users.${config.nixdots.core.primaryUser.username} = {
      dconf.settings = {
        # Interface & desktop behaviour
        "org/gnome/desktop/interface" = {
          show-battery-percentage = true;
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          enable-animations = false;
        };

        # Input devices
        "org/gnome/desktop/peripherals/touchpad" = {
          click-method = "areas";
        };

        # Privacy
        "org/gnome/desktop/privacy" = {
          remember-recent-files = false;
        };

        # Power management
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          ambient-enabled = false;
        };

        # GNOME Shell keybindings
        "org/gnome/shell/keybindings" = {
          toggle-quick-settings = [ ];
          switch-to-application-1 = [ ];
          switch-to-application-2 = [ ];
          switch-to-application-3 = [ ];
          switch-to-application-4 = [ ];
        };

        # Window manager keybindings
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>w" ];
          panel-run-dialog = [ "<Super>r" ];
          toggle-maximized = [ "<Super>s" ];

          switch-applications = [ ];
          switch-applications-backward = [ ];

          switch-windows = [ "<Alt>Tab" ];
          switch-windows-backward = [ "<Shift><Alt>Tab" ];

          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];

          move-to-workspace-1 = [ "<Shift><Super>1" ];
          move-to-workspace-2 = [ "<Shift><Super>2" ];
          move-to-workspace-3 = [ "<Shift><Super>3" ];
          move-to-workspace-4 = [ "<Shift><Super>4" ];
        };

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = "wezterm";
          name = "Terminal";
        };
      };
    };
  };
}
