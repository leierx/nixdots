root: {
  flake.modules.homeManager.hyprland =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) types;
      inherit (lib.generators) mkLuaInline;

      # sound-name hints are looked up here
      soundTheme = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo";

      sound =
        urgency: default:
        lib.mkOption {
          type = types.nullOr types.path;
          inherit default;
          description = "Sound file for ${urgency} urgency notifications, or null for silence.";
        };

      singleton = name: type: values: ''
        pragma Singleton

        import QtQuick
        import Quickshell

        Singleton {
        ${
          lib.concatStrings (
            lib.mapAttrsToList (n: v: "  readonly property ${type} ${n}: ${builtins.toJSON v}\n") values
          )
        }}
      '';

      shell = pkgs.runCommand "quickshell-shell" { } ''
        cp -r ${./quickshell} $out
        chmod -R u+w $out
        mkdir $out/nix
        cp ${
          pkgs.writeText "Colors.qml" (singleton "Colors" "color" root.config.palettes.ui)
        } $out/nix/Colors.qml
        cp ${pkgs.writeText "Bin.qml" (singleton "Bin" "string" config.quickshell.bin)} $out/nix/Bin.qml
        cp ${
          pkgs.writeText "Sounds.qml" (
            singleton "Sounds" "string" (
              lib.mapAttrs (
                _: sound: if sound == null then "" else "${sound}"
              ) config.quickshell.notificationSounds
              // {
                theme = soundTheme;
              }
            )
          )
        } $out/nix/Sounds.qml
      '';

      menuBind = key: menu: desc: {
        _args = [
          (mkLuaInline ''mod .. " + ${key}"'')
          (mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON "${lib.getExe config.programs.quickshell.package} ipc -c shell call menu toggle ${menu}"})")
          { description = desc; }
        ];
      };
    in
    {
      options.quickshell.bin = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Executables the shell runs, read in QML as `Bin.<name>`.";
      };

      options.quickshell.notificationSounds = {
        low = sound "low" null;
        normal = sound "normal" "${soundTheme}/message-new-instant.oga";
        critical = sound "critical" "${soundTheme}/dialog-warning.oga";
      };

      config = {
        # Theme.qml's fonts and shell.qml's icon theme
        home.packages = [
          pkgs.adwaita-fonts
          pkgs.papirus-icon-theme
        ];

        quickshell.bin = {
          terminal = lib.getExe config.programs.wezterm.package;
          systemdRun = lib.getExe' osConfig.systemd.package "systemd-run";
          notifySend = lib.getExe' pkgs.libnotify "notify-send";
          xdgOpen = lib.getExe' pkgs.xdg-utils "xdg-open";
          pwPlay = lib.getExe' pkgs.pipewire "pw-play";
          cliphist = lib.getExe config.services.cliphist.package;
          cliphistCopy = lib.getExe (
            pkgs.writeShellApplication {
              name = "cliphist-copy";
              runtimeInputs = [
                config.services.cliphist.package
                config.services.cliphist.clipboardPackage
              ];
              text = ''cliphist decode "$1" | wl-copy'';
            }
          );
        };

        programs.quickshell = {
          enable = true;
          # 0.3.1 fixed crashes on freed objects in a ScriptModel, which the notification lists hold
          package = pkgs.unstable.quickshell;
          configs.shell = shell;
          activeConfig = "shell";
          systemd.enable = true;
        };
        systemd.user.services.quickshell.Unit = {
          PartOf = [ config.wayland.systemd.target ];
          X-Restart-Triggers = [ "${shell}" ];
        };

        wayland.windowManager.hyprland.settings.bind = [
          (menuBind "d" "apps" "App launcher")
          (menuBind "v" "clipboard" "Clipboard history")
          # SUPER+P, after Windows' display "Project" switcher
          (menuBind "P" "monitors" "Monitor layouts")
          (menuBind "n" "notifications" "Notifications")
        ];
      };
    };
}
