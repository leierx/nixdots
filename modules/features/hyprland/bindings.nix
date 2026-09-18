{
  flake.modules.homeManager.hyprland = { pkgs, lib, ... }: {
    wayland.windowManager.hyprland = {
      settings = {
        bind =
          let
            inherit (lib.generators) mkLuaInline;

            mkBind =
              {
                key,
                dispatcher,
                modifiers ? [ ],
                mouse ? false,
              }:
              let
                bindKey = lib.concatStringsSep " + " (modifiers ++ [ key ]);
              in
              {
                _args = [
                  (mkLuaInline ''mod .. " + ${bindKey}"'')
                  (mkLuaInline dispatcher)
                ]
                ++ lib.optional mouse { inherit mouse; };
              };
          in
          [
            # MOUSE BINDINGS #
            (mkBind {
              key = "mouse:272";
              dispatcher = "hl.dsp.window.drag()";
              mouse = true;
            })
            (mkBind {
              key = "mouse:273";
              dispatcher = "hl.dsp.window.resize()";
              mouse = true;
            })
            # launchers
            (mkBind {
              key = "Return";
              dispatcher = ''hl.dsp.exec_cmd("${pkgs.wezterm}/bin/wezterm")'';
            })
            (mkBind {
              key = "d";
              dispatcher = ''hl.dsp.exec_cmd("${pkgs.rofi}/bin/rofi -modes drun -show drun")'';
            })
            (mkBind {
              key = "v";
              dispatcher = ''hl.dsp.exec_cmd("${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -display-columns 2 -theme-str 'window {width: 50%;height: 75%;} entry {placeholder: \"Clipboard\";}' | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy")'';
            })
            # window control
            (mkBind {
              key = "w";
              dispatcher = "hl.dsp.window.close()";
            })
            (mkBind {
              key = "s";
              dispatcher = ''hl.dsp.window.float({ action = "toggle" })'';
            })
            (mkBind {
              key = "f";
              dispatcher = "hl.dsp.window.fullscreen()";
            })
            (mkBind {
              key = "m";
              dispatcher = "hl.dsp.window.fullscreen({ mode = 1 })";
            })
            # monitors
            (mkBind {
              key = "o";
              dispatcher = ''hl.dsp.focus({ monitor = "+1" })'';
            })
            (mkBind {
              key = "o";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ monitor = "+1" })'';
            })
            # cycling
            (mkBind {
              key = "c";
              dispatcher = ''
                function()
                  hl.dispatch(hl.dsp.window.cycle_next())
                  hl.dispatch(hl.dsp.window.bring_to_top())
                end'';
            })
            # focus workspaces
            (mkBind {
              key = "1";
              dispatcher = ''hl.dsp.focus({ workspace = "m~1" })'';
            })
            (mkBind {
              key = "2";
              dispatcher = ''hl.dsp.focus({ workspace = "m~2" })'';
            })
            (mkBind {
              key = "3";
              dispatcher = ''hl.dsp.focus({ workspace = "m~3" })'';
            })
            (mkBind {
              key = "4";
              dispatcher = ''hl.dsp.focus({ workspace = "m~4" })'';
            })
            (mkBind {
              key = "5";
              dispatcher = ''hl.dsp.focus({ workspace = "m~5" })'';
            })
            # move window to workspaces on monitor
            (mkBind {
              key = "1";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ workspace = "m~1", follow = false })'';
            })
            (mkBind {
              key = "2";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ workspace = "m~2", follow = false })'';
            })
            (mkBind {
              key = "3";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ workspace = "m~3", follow = false })'';
            })
            (mkBind {
              key = "4";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ workspace = "m~4", follow = false })'';
            })
            (mkBind {
              key = "5";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ workspace = "m~5", follow = false })'';
            })
            # focus directions
            (mkBind {
              key = "h";
              dispatcher = ''hl.dsp.focus({ direction = "l" })'';
            })
            (mkBind {
              key = "l";
              dispatcher = ''hl.dsp.focus({ direction = "r" })'';
            })
            (mkBind {
              key = "k";
              dispatcher = ''hl.dsp.focus({ direction = "u" })'';
            })
            (mkBind {
              key = "j";
              dispatcher = ''hl.dsp.focus({ direction = "d" })'';
            })
            # move window in directions
            (mkBind {
              key = "h";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ direction = "l" })'';
            })
            (mkBind {
              key = "l";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ direction = "r" })'';
            })
            (mkBind {
              key = "k";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ direction = "u" })'';
            })
            (mkBind {
              key = "j";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ direction = "d" })'';
            })
            # screenshot — freeze, slurp region, copy PNG to clipboard
            (mkBind {
              key = "Q";
              dispatcher = ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-copy" (builtins.readFile ./scripts/freeze-region-copy.sh)}")'';
            })
            # screenshot — same, but save to ~/Pictures/screenshots/
            (mkBind {
              key = "Q";
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-save" (builtins.readFile ./scripts/freeze-region-save.sh)}")'';
            })
            # SUBMAPS
            {
              _args = [
                (mkLuaInline ''mod .. " + X"'')
                (mkLuaInline ''
                  function()
                           hl.dispatch(hl.dsp.submap("system_control"))
                           hl.timer(function() hl.dispatch(hl.dsp.submap("reset")) end,
                                    { timeout = 2000, type = "oneshot" })
                         end'')
              ];
            }
          ];
      };
      submaps.system_control = {
        onDispatch = "reset"; # auto-exits the submap after any dispatch
        settings.bind =
          let
            inherit (lib.generators) mkLuaInline;
          in
          [
            # shut down
            {
              _args = [
                "ESCAPE"
                (mkLuaInline ''hl.dsp.exec_cmd("systemctl poweroff")'')
              ];
            }

            # exit hyprland
            {
              _args = [
                "Q"
                (mkLuaInline "hl.dsp.exit()")
              ];
            }

            # reload config-only (R alone) and full reload (mod+R)
            {
              _args = [
                "R"
                (mkLuaInline ''hl.dsp.exec_cmd("hyprctl reload")'')
              ];
            }

            # lockscreen
            {
              _args = [
                "L"
                (mkLuaInline "hl.dsp.exec_cmd(lockscreen_cmd)")
              ];
            }
          ];
      };
    };
  };
}
