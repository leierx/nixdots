root:
let
  # in the shell's PATH and in qs-test's, which runs the real thing against a fake /dev and sysfs
  helpers = pkgs: {
    cameraUsers = pkgs.stdenv.mkDerivation {
      name = "camera-users";
      src = ./scripts/camera-users.c;
      dontUnpack = true;
      buildPhase = "$CC -O2 -Wall -Werror -o camera-users $src";
      installPhase = "install -Dm755 camera-users $out/bin/camera-users";
      meta.mainProgram = "camera-users";
    };
    # udevadm is the base system's, so qs-test can stand a fake in
    backlightWatch = pkgs.writeShellApplication {
      name = "backlight-watch";
      runtimeInputs = [ pkgs.coreutils ];
      text = builtins.readFile ./scripts/backlight-watch.sh;
    };
  };
in
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
      inherit (helpers pkgs) cameraUsers backlightWatch;

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
            ) root.config.palettes.adwaita_darker
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

      # Material Design Icons as path data, the set Nerd Fonts ships as nf-md
      symbols =
        let
          mdi = pkgs.fetchzip {
            url = "https://registry.npmjs.org/@mdi/svg/-/svg-7.4.47.tgz";
            hash = "sha256-7wQn4z0r1ebE2ovuF3H1ho2glB5x0bsax5rA7Q8/Ez4=";
          };
        in
        pkgs.runCommand "Symbols.qml" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
          cp ${./scripts/symbols.mjs} symbols.mjs
          cp ${./scripts/symbols.tsv} symbols.tsv
          node symbols.mjs ${mdi}/svg > $out
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
        cp ${symbols} $out/nix/Symbols.qml
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
          pkgs.gnused
          pkgs.jq
          pkgs.libnotify
          securityContext
        ];
        text = ''
          terminal=${lib.escapeShellArg (lib.getExe config.programs.wezterm.package)}
          progress=${./scripts/nixpkgs-progress.jq}
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
      imports = [
        {
          options.quickshell.scale = lib.mkOption {
            type = lib.types.numbers.positive;
            default = 1;
            description = "How much larger than libadwaita's sizes the shell draws, on top of each monitor's own scale (Qt's QT_SCALE_FACTOR).";
          };
        }
      ];

      home.packages = [
        # Theme.qml's fonts and shell.qml's icon theme
        pkgs.adwaita-fonts
        pkgs.papirus-icon-theme
        # run by name from the QML; hyprmoncfg and wezterm come with their own features
        pkgs.libnotify
        pkgs.pipewire
        pkgs.wireplumber
        pkgs.wl-clipboard
        pkgs.xdg-utils
        config.services.cliphist.package
        nixpkgsIndex
        nixpkgsRun
        cameraUsers
        backlightWatch
        # the control centre's brightness, set through logind
        pkgs.brightnessctl
        # its Audio Settings
        pkgs.pwvucontrol
      ]
      ++ lib.optionals osConfig.networking.networkmanager.enable [
        # the control centre's VPNs, and its Network Settings…
        osConfig.networking.networkmanager.package
        pkgs.networkmanagerapplet
      ];

      # The control centre's night light: started without a tint, which the shell sets while it runs.
      services.hyprsunset = {
        enable = true;
        extraArgs = [ "--identity" ];
      };

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
          # cliphist wipes its history as it starts; the shell then prunes the pictures it decoded from it
          After = [ "cliphist.service" ];
          X-Restart-Triggers = [ "${shell}" ];
          # a crash loop through a burst of hotplugs must not leave the session without a shell
          StartLimitIntervalSec = 0;
        };
        Service = {
          RestartSec = 1;
          # about 500 MiB in use; a runaway is restarted rather than swapping the desktop out
          MemoryMax = "2G";
          MemorySwapMax = 0;
          Environment = [ "QT_SCALE_FACTOR=${builtins.toJSON config.quickshell.scale}" ];
        };
      };

      # The control centre's Caffeine: hypridle honours logind's idle inhibitors, and a unit outlives a shell restart.
      systemd.user.services.caffeine = {
        Unit = {
          Description = "Keep the session from going idle";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
        };
        Service.ExecStart = lib.escapeShellArgs [
          (lib.getExe' osConfig.systemd.package "systemd-inhibit")
          "--what=idle"
          "--who=Caffeine"
          "--why=Turned on in the control centre"
          "--mode=block"
          (lib.getExe' pkgs.coreutils "sleep")
          "infinity"
        ];
      };

      # Hyprland reports no lock changes, so the Caps Lock key's release asks the shell to look.
      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "input.keyboard.key"
            (mkLuaInline ''
              function(keycode, _, state)
                if keycode == 66 and state == 0 then hl.dispatch(hl.dsp.global("quickshell:caps-lock")) end
              end'')
          ];
        }
      ];

      wayland.windowManager.hyprland.settings.bind = [
        (globalBind "d" "launcher-apps" "App launcher")
        (globalBind "v" "launcher-clipboard" "Clipboard history")
        # SUPER+P, after Windows' display "Project" switcher
        (globalBind "p" "launcher-monitors" "Monitor layouts")
        (globalBind "Tab" "launcher-windows" "Window switcher")
        (globalBind "n" "launcher-nixpkgs" "Run from nixpkgs")
        # SUPER+A, as Windows 11 opens its quick settings
        (globalBind "a" "controls" "Control centre")
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
      inherit (helpers pkgs) cameraUsers backlightWatch;

      qsDesignLint = pkgs.writeShellApplication {
        name = "qs-design-lint";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
        ];
        text = builtins.readFile ./scripts/qs-design-lint.sh;
      };

      qsLint = pkgs.writeShellApplication {
        name = "qs-lint";
        runtimeInputs = [
          qtdeclarative
          qsDesignLint
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

      # one virtual pointer and keyboard for the whole session: a device per call drops the seat's
      # capability between calls, and the first event after one comes back is lost
      qsInput = pkgs.stdenv.mkDerivation {
        name = "qs-input";
        src = ./scripts/qs-input.c;
        dontUnpack = true;
        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.wayland-scanner
        ];
        buildInputs = [
          pkgs.wayland
          pkgs.libxkbcommon
        ];
        buildPhase = ''
          for xml in \
            ${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-virtual-pointer-unstable-v1.xml \
            ${pkgs.wtype.src}/protocol/virtual-keyboard-unstable-v1.xml; do
            name=$(basename "$xml" .xml)
            wayland-scanner client-header "$xml" "$name-client-protocol.h"
            wayland-scanner private-code "$xml" "$name-protocol.c"
          done
          $CC -O2 -Wall -Werror -I. -o qs-input "$src" *-protocol.c \
            $(pkg-config --cflags --libs wayland-client xkbcommon)
        '';
        installPhase = "install -Dm755 qs-input $out/bin/qs-input";
        meta.mainProgram = "qs-input";
      };

      # tray items whose menus can be clicked through without touching anything real: one with submenus, or `qs-tray NAME COUNT`
      qsTray =
        let
          tray = pkgs.runCommand "qs-tray-qml" { } ''
            mkdir $out
            cp ${./tests/tray.qml} $out/tray.qml
            cp ${./tests/trays.qml} $out/trays.qml
            cp ${./tests/tray-icon.svg} $out/icon.svg
          '';
        in
        pkgs.writeShellScriptBin "qs-tray" ''
          export QT_PLUGIN_PATH=${
            lib.concatMapStringsSep ":" (qt: "${qt}/lib/qt-6/plugins") [
              unstable.qt6.qtbase
              unstable.qt6.qtwayland
              unstable.qt6.qtsvg
            ]
          }
          export QML_IMPORT_PATH=${qtdeclarative}/lib/qt-6/qml
          export QT_FORCE_STDERR_LOGGING=1
          if [ $# -gt 0 ]; then exec ${qtdeclarative}/bin/qml ${tray}/trays.qml -- "$@"; fi
          exec ${qtdeclarative}/bin/qml ${tray}/tray.qml
        '';

      # fakes of NetworkManager, UPower, BlueZ and logind on the session's own system bus (tests/*.py, or dbusmock's templates)
      qsDbusmock = pkgs.writeShellScriptBin "qs-dbusmock" ''
        exec ${
          pkgs.python3.withPackages (ps: [
            ps.python-dbusmock
            ps.pygobject3
            ps.dbus-python
          ])
        }/bin/python3 -m dbusmock "$@"
      '';

      # notifications by the thousand, faster than one notify-send each
      qsFlood = pkgs.writers.writePython3Bin "qs-flood" {
        libraries = [ pkgs.python3Packages.jeepney ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./scripts/qs-flood.py);

      qsTest = pkgs.writeShellApplication {
        name = "qs-test";
        runtimeInputs = with pkgs; [
          # gdbus, which sends a notification a picture held only in memory
          glib
          quickshell
          qsLint
          qsInput
          qsTray
          qsFlood
          qsDbusmock
          networkmanager
          # a light window, dozens of which crowd a workspace
          foot
          cameraUsers
          backlightWatch
          pipewire
          wireplumber
          labwc
          grim
          jq
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

      # A pure script's qmltestrunner test, with only that script beside it.
      qmlTest =
        name: script: test:
        pkgs.runCommand name { } ''
          mkdir -p quickshell/${dirOf script} tests
          cp ${./quickshell + "/${script}"} quickshell/${script}
          cp ${./tests + "/${test}"} tests/${test}
          XDG_CACHE_HOME=$TMPDIR QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=${unstable.qt6.qtbase}/lib/qt-6/plugins \
            QML_IMPORT_PATH=${qtdeclarative}/lib/qt-6/qml \
            ${qtdeclarative}/bin/qmltestrunner -input tests/${test}
          touch "$out"
        '';
    in
    lib.optionalAttrs (lib.hasSuffix "-linux" system) {
      packages.qs-test = qsTest;
      # writeShellApplication shellchecks it, which only building it runs.
      checks.qs-test = qsTest;
      checks.qmllint = pkgs.runCommand "qmllint" { } ''
        ${lib.concatMapStrings (shell: "${lib.getExe qsLint} ${shell}\n") (lib.unique shells)}
        touch "$out"
      '';
      # The notification body filter, which no lint can see is right.
      checks.notification-markup =
        qmlTest "notification-markup" "notifications/markup.js"
          "tst_markup.qml";
      # The saved history, which a damaged file must never break.
      checks.notification-history =
        qmlTest "notification-history" "notifications/history.js"
          "tst_history.qml";
      checks.launcher-search = qmlTest "launcher-search" "launcher/search.js" "tst_search.qml";
      # Names from hostile networks and devices, kept to one line.
      checks.names = qmlTest "names" "controls/names.js" "tst_names.qml";
      # What symbol a sound device gets, from what PipeWire tells of it.
      checks.sound-devices = qmlTest "sound-devices" "controls/devices.js" "tst_devices.qml";
    };
}
