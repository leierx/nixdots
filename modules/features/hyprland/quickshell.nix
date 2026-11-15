root@{ inputs, ... }:
{
  flake.modules.homeManager.hyprland =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.generators) mkLuaInline;

      # the same derivation hyprmoncfg.nix installs; its hyprctl must match the running compositor
      hyprmoncfg =
        inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hyprmoncfg.override
          { hyprland = config.wayland.windowManager.hyprland.package; };

      # read in QML as Bin.<name>
      bin = {
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
        hyprmoncfg = lib.getExe hyprmoncfg;
        applyMonitorLayout = lib.getExe (
          pkgs.writeShellApplication {
            name = "apply-monitor-layout";
            runtimeInputs = [
              hyprmoncfg
              pkgs.libnotify
            ];
            text = ''
              if ! out=$(hyprmoncfg apply --confirm-timeout 0 "$1" 2>&1); then
                notify-send -u critical "hyprmoncfg: $1" "$out"
              fi
            '';
          }
        );
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
        cp ${pkgs.writeText "Bin.qml" (singleton "Bin" "string" bin)} $out/nix/Bin.qml
      '';

      ipcBind = key: call: desc: {
        _args = [
          (mkLuaInline ''mod .. " + ${key}"'')
          (mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON "${lib.getExe config.programs.quickshell.package} ipc -c shell call ${call}"})")
          { description = desc; }
        ];
      };
    in
    {
      # Theme.qml's fonts and shell.qml's icon theme
      home.packages = [
        pkgs.adwaita-fonts
        pkgs.papirus-icon-theme
      ];

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
        (ipcBind "d" "launcher toggle apps" "App launcher")
        (ipcBind "v" "launcher toggle clipboard" "Clipboard history")
        # SUPER+P, after Windows' display "Project" switcher
        (ipcBind "P" "launcher toggle monitors" "Monitor layouts")
        (ipcBind "n" "notifications toggle" "Notifications")
      ];
    };
}
