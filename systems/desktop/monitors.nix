{ lib, pkgs, ... }:
{
  systemd.tmpfiles.rules =
    let
      gdmMonitorConfigMultiline = ''
        <monitors version="2">
          <configuration>
            <logicalmonitor>
              <x>0</x>
              <y>0</y>
              <scale>1</scale>
              <monitor>
                <monitorspec>
                  <connector>DP-1</connector>
                  <vendor>AOC</vendor>
                  <product>Q27G2G4</product>
                  <serial>0x000023bd</serial>
                </monitorspec>
                <mode>
                  <width>2560</width>
                  <height>1440</height>
                  <rate>143.912</rate>
                </mode>
              </monitor>
            </logicalmonitor>
            <logicalmonitor>
              <x>2560</x>
              <y>0</y>
              <scale>1</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>DP-2</connector>
                  <vendor>AOC</vendor>
                  <product>Q27G2G4</product>
                  <serial>0x000021bd</serial>
                </monitorspec>
                <mode>
                  <width>2560</width>
                  <height>1440</height>
                  <rate>143.912</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      '';

      # Trimming
      gdmMonitorConfig = builtins.replaceStrings [ "\n" "  " ] [ " " "" ] gdmMonitorConfigMultiline;
    in
    [
      "f+ /run/gdm/.config/monitors.xml - gdm gdm - ${gdmMonitorConfig}"
    ];

  services.xserver.xrandrHeads = [
    {
      output = "DisplayPort-0";
      monitorConfig = ''
        Option "Position" "0 0"
        Option "Enable" "true"
        Option "Rotate" "normal"
        Option "PreferredMode" "2560x1440_144"
      '';
    }
    {
      output = "DisplayPort-1";
      primary = true;
      monitorConfig = ''
        Option "Position" "2560 0"
        Option "Enable" "true"
        Option "Rotate" "normal"
        Option "PreferredMode" "2560x1440_144"
      '';
    }
  ];

  home-manager.sharedModules = [
    ({
      systemd.user.services.kanshi = lib.mkForce { }; # disable the systemd service.
      services.kanshi = {
        enable = true;
        settings = [
          {
            profile.name = "main";
            profile.outputs = [
              {
                criteria = "AOC Q27G2G4 0x000021BD";
                mode = "2560x1440@143.91Hz";
                position = "2560,0";
              }
              {
                criteria = "AOC Q27G2G4 0x000023BD";
                mode = "2560x1440@143.91Hz";
                position = "0,0";
              }
            ];
          }
        ];
      };

      wayland.windowManager.hyprland.settings.exec = [
        "pgrep ${pkgs.kanshi}/bin/kanshi || ${pkgs.kanshi}/bin/kanshi &"
        "pgrep ${pkgs.kanshi}/bin/kanshi && ${pkgs.kanshi}/bin/kanshictl reload"
      ];
    })
  ];
}
