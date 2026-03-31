{ config, self, ... }:
{
  flake.modules.nixos.gnome =
    { pkgs, ... }:
    {
      # terminal of choice
      imports = [ self.modules.homeManager.wezterm ];

      services.desktopManager.gnome.enable = true;

      services.gnome.core-apps.enable = false;
      services.gnome.core-developer-tools.enable = false;
      services.gnome.gnome-online-accounts.enable = false;
      services.gnome.games.enable = false;

      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        gnome-user-docs
      ];

      home-manager.users.${config.flake.settings.user.username}.imports = [ self.modules.homeManager.gnome ];
    };

  flake.modules.homeManager.gnome = {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        show-battery-percentage = true;
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
        enable-animations = false;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "areas";
      };

      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        ambient-enabled = false;
      };

      "org/gnome/shell/keybindings" = {
        toggle-quick-settings = [ ];
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
      };

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
}
