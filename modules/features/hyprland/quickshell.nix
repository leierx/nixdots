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
      inherit (lib.generators) mkLuaInline;

      # Qt reads #aarrggbb where the palette has CSS's #rrggbbaa
      qtColor =
        value:
        if lib.stringLength value == 9 then
          "#${lib.substring 7 2 value}${lib.substring 1 6 value}"
        else
          value;

      colors = pkgs.writeText "Colors.qml" ''
        pragma Singleton

        import QtQuick
        import Quickshell

        Singleton {
        ${
          lib.concatStrings (
            lib.mapAttrsToList (
              name: value: "  readonly property color ${name}: ${builtins.toJSON (qtColor value)}\n"
            ) root.config.palettes.adwaita_dark
          )
        }}
      '';

      hyprsplit = pkgs.writeText "Hyprsplit.qml" ''
        pragma Singleton

        import Quickshell

        Singleton {
          readonly property int workspaces: ${toString root.config.hyprland.workspaces}
        }
      '';

      # MET Norway's weather symbols, named by its symbol codes
      weathericons = pkgs.fetchFromGitHub {
        owner = "metno";
        repo = "weathericons";
        rev = "89e3173756248b4696b9b10677b66c4ef435db53";
        hash = "sha256-Kv6GujllD3shrrkndod6WDrby8CaytKQoaQgJ/q9ul8=";
      };

      shell = pkgs.runCommand "quickshell-shell" { } ''
        cp -r ${./quickshell} $out
        chmod -R u+w $out
        mkdir $out/nix
        cp ${colors} $out/nix/Colors.qml
        cp ${hyprsplit} $out/nix/Hyprsplit.qml
        mkdir $out/weather/icons
        cp ${weathericons}/weather/svg/*.svg ${weathericons}/weather/legend.csv $out/weather/icons/
      '';

      nixpkgsIndex = pkgs.writeShellApplication {
        name = "nixpkgs-index";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          jq
        ];
        text = builtins.readFile ./scripts/nixpkgs-index.sh;
      };

      nixpkgsRun = pkgs.writeShellApplication {
        name = "nixpkgs-run";
        runtimeInputs = [
          osConfig.nix.package
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.libnotify
        ];
        text = ''
          terminal=${lib.escapeShellArg (lib.getExe config.programs.wezterm.package)}
        ''
        + builtins.readFile ./scripts/nixpkgs-run.sh;
      };

      notifyTest = pkgs.writeShellApplication {
        name = "notify-test";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.libnotify
          config.programs.quickshell.package
        ];
        text = ''
          wide=${./assets/wallpaper.png}
          photo=${./assets/lockscreen-background.jpg}
          bell=${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/bell.oga
        ''
        + builtins.readFile ./scripts/notify-test.sh;
      };

      # a GlobalShortcut in the shell, reached without starting a `qs ipc` process
      globalBind = key: name: desc: {
        _args = [
          (mkLuaInline ''mod .. " + ${key}"'')
          (mkLuaInline "hl.dsp.global(${builtins.toJSON "quickshell:${name}"})")
          { description = desc; }
        ];
      };
    in
    {
      home.packages = [
        # Theme.qml's fonts and shell.qml's icon theme
        pkgs.adwaita-fonts
        pkgs.papirus-icon-theme
        # run by name from the QML; hyprmoncfg and wezterm come with their own features
        pkgs.libnotify
        pkgs.pipewire
        pkgs.wl-clipboard
        pkgs.xdg-utils
        config.services.cliphist.package
        nixpkgsIndex
        nixpkgsRun
        notifyTest
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
        (globalBind "d" "launcher-apps" "App launcher")
        (globalBind "v" "launcher-clipboard" "Clipboard history")
        # SUPER+P, after Windows' display "Project" switcher
        (globalBind "p" "launcher-monitors" "Monitor layouts")
        (globalBind "Tab" "launcher-windows" "Window switcher")
        (globalBind "n" "launcher-nixpkgs" "Run from nixpkgs")
        # SUPER+?, as GTK apps show theirs on Ctrl+?; Hyprland matches the unshifted key, plus on the no layout
        (globalBind "SHIFT + plus" "shortcuts" "Keyboard shortcuts")
      ];
    };
}
