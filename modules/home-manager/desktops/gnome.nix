{
  imports = [
    ../wezterm.nix # terminal emulator of choice
  ];

  config = {
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
        # Do nothing when idle on AC power (no automatic suspend)
        sleep-inactive-ac-type = "nothing";
        # Disable ambient light-based brightness adjustment
        ambient-enabled = false;
      };

      # GNOME Shell keybindings
      "org/gnome/shell/keybindings" = {
        toggle-quick-settings = [];
        switch-to-application-1 = [];
        switch-to-application-2 = [];
        switch-to-application-3 = [];
        switch-to-application-4 = [];
      };

      # Window manager keybindings
      "org/gnome/desktop/wm/keybindings" = {
        # Close window with Super+W
        close = [ "<Super>w" ];
        # Run command dialog with Super+R
        panel-run-dialog = [ "<Super>r" ];
        # Toggle maximized state with Super+S
        toggle-maximized = [ "<Super>s" ];
        # Disable application-based Alt+Tab (use window-based instead)
        switch-applications = [];
        switch-applications-backward = [];
        # Use Alt+Tab for switching windows
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        # Use Super+1..4 to jump to workspaces 1–4
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        # Use Shift+Super+1..4 to move the focused window to workspaces 1–4
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
}
