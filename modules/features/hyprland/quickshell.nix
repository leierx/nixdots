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

      securityContext = pkgs.stdenv.mkDerivation {
        name = "security-context";
        src = ./scripts/security-context.c;
        dontUnpack = true;
        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.wayland-scanner
        ];
        buildInputs = [ pkgs.wayland ];
        buildPhase = ''
          xml=${pkgs.wayland-protocols}/share/wayland-protocols/staging/security-context/security-context-v1.xml
          wayland-scanner client-header "$xml" security-context-v1-client-protocol.h
          wayland-scanner private-code "$xml" security-context-v1-protocol.c
          $CC -O2 -Wall -Werror -I. -o security-context "$src" security-context-v1-protocol.c $(pkg-config --cflags --libs wayland-client)
        '';
        installPhase = "install -Dm755 security-context $out/bin/security-context";
        meta.mainProgram = "security-context";
      };

      nixpkgsRun = pkgs.writeShellApplication {
        name = "nixpkgs-run";
        runtimeInputs = [
          osConfig.nix.package
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.libnotify
          securityContext
        ];
        text = ''
          terminal=${lib.escapeShellArg (lib.getExe config.programs.wezterm.package)}
        ''
        + builtins.readFile ./scripts/nixpkgs-run.sh;
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
      ];

      programs.quickshell = {
        enable = true;
        # 0.3.1 fixed crashes on freed objects in a ScriptModel, which the notification lists hold
        package = pkgs.unstable.quickshell;
        configs.shell = shell;
        activeConfig = "shell";
        systemd.enable = true;
      };
      systemd.user.services.quickshell = {
        Unit = {
          PartOf = [ config.wayland.systemd.target ];
          X-Restart-Triggers = [ "${shell}" ];
          # a crash loop through a burst of hotplugs must not leave the session without a shell
          StartLimitIntervalSec = 0;
        };
        Service.RestartSec = 1;
      };

      wayland.windowManager.hyprland.settings.bind = [
        (globalBind "d" "launcher-apps" "App launcher")
        (globalBind "v" "launcher-clipboard" "Clipboard history")
        # SUPER+P, after Windows' display "Project" switcher
        (globalBind "p" "launcher-monitors" "Monitor layouts")
        (globalBind "Tab" "launcher-windows" "Window switcher")
        (globalBind "n" "launcher-nixpkgs" "Run from nixpkgs")
        (globalBind "x" "power" "Power menu")
        # SUPER+?, as GTK apps show theirs on Ctrl+?; Hyprland matches the unshifted key, plus on the no layout
        (globalBind "SHIFT + plus" "shortcuts" "Keyboard shortcuts")
      ];
    };

  perSystem =
    {
      pkgs,
      lib,
      inputs,
      system,
      ...
    }:
    let
      # the session's own quickshell (pkgs.unstable on the hosts) and the Qt it was built with
      unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
      inherit (unstable) quickshell;
      inherit (unstable.qt6) qtdeclarative;

      qsLint = pkgs.writeShellApplication {
        name = "qs-lint";
        runtimeInputs = [
          qtdeclarative
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
          pkgs.jq
        ];
        text = ''
          quickshellQml=${quickshell}/lib/qt-6/qml
          qtQml=${qtdeclarative}/lib/qt-6/qml
        ''
        + builtins.readFile ./scripts/qs-lint.sh;
      };

      qsTest = pkgs.writeShellApplication {
        name = "qs-test";
        runtimeInputs = with pkgs; [
          quickshell
          qsLint
          sway
          swaybg
          grim
          wtype
          wlrctl
          dbus
          libnotify
          git
          coreutils
          findutils
          gawk
          gnugrep
          util-linux
        ];
        text = builtins.readFile ./scripts/qs-test.sh;
      };

      shells =
        map
          (
            host:
            host.config.home-manager.users.${root.config.identity.username}.programs.quickshell.configs.shell
          )
          (
            lib.filter (
              host:
              host.pkgs.stdenv.hostPlatform.system == system
              && (host.config.home-manager.users.${root.config.identity.username}.programs.quickshell.enable
                or false
              )
            ) (lib.attrValues root.config.flake.nixosConfigurations)
          );
    in
    lib.optionalAttrs (lib.hasSuffix "-linux" system) {
      packages.qs-test = qsTest;
      checks.qmllint = pkgs.runCommand "qmllint" { } ''
        ${lib.concatMapStrings (shell: "${lib.getExe qsLint} ${shell}\n") (lib.unique shells)}
        touch "$out"
      '';
    };
}
