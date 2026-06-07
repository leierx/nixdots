{
  modules.homeManager.hyprland = { pkgs, lib, ... }: {
    wayland.windowManager.hyprland = {
      settings = {
        bind =
          let
            inherit (lib.generators) mkLuaInline;

            mkBind = key: dispatcher: {
              _args = [
                (mkLuaInline ''mod .. " + ${key}"'')
                (mkLuaInline dispatcher)
              ];
            };
          in
          [
            # MOUSE BINDINGS #
            {
              _args = [
                (mkLuaInline ''mod .. "+ mouse:272"'')
                (mkLuaInline "hl.dsp.window.drag(), { mouse = true }")
              ];
            }
            {
              _args = [
                (mkLuaInline ''mod .. "+ mouse:273"'')
                (mkLuaInline "hl.dsp.window.resize(), { mouse = true }")
              ];
            }
            # launchers
            (mkBind "Return" "hl.dsp.exec_cmd(terminal_cmd)")
            (mkBind "d" "hl.dsp.exec_cmd(applicationLauncher_cmd)")
            # window control
            (mkBind "w" "hl.dsp.window.close()")
            (mkBind "s" ''hl.dsp.window.float({ action = "toggle" })'')
            (mkBind "f" "hl.dsp.window.fullscreen()")
            (mkBind "m" "hl.dsp.window.fullscreen({ mode = 1 })")
            # monitors
            (mkBind "o" ''hl.dsp.focus({ monitor = "+1" })'')
            (mkBind "SHIFT + o" ''hl.dsp.window.move({ monitor = "+1" })'')
            # cycling
            (mkBind "c" "hl.dsp.window.cycle_next()")
            (mkBind "SHIFT + c" "hl.dsp.window.swap_next()")
            # focus workspaces
            (mkBind "1" ''hl.dsp.focus({ workspace = "r~1" })'')
            (mkBind "2" ''hl.dsp.focus({ workspace = "r~2" })'')
            (mkBind "3" ''hl.dsp.focus({ workspace = "r~3" })'')
            (mkBind "4" ''hl.dsp.focus({ workspace = "r~4" })'')
            (mkBind "5" ''hl.dsp.focus({ workspace = "r~5" })'')
            # focus directions
            (mkBind "h" ''hl.dsp.focus({ direction = "l" })'')
            (mkBind "l" ''hl.dsp.focus({ direction = "r" })'')
            (mkBind "k" ''hl.dsp.focus({ direction = "u" })'')
            (mkBind "j" ''hl.dsp.focus({ direction = "d" })'')
            # move window to workspaces on monitor
            (mkBind "SHIFT + 1" ''hl.dsp.window.move({ workspace = "r~1" })'')
            (mkBind "SHIFT + 2" ''hl.dsp.window.move({ workspace = "r~2" })'')
            (mkBind "SHIFT + 3" ''hl.dsp.window.move({ workspace = "r~3" })'')
            (mkBind "SHIFT + 4" ''hl.dsp.window.move({ workspace = "r~4" })'')
            (mkBind "SHIFT + 5" ''hl.dsp.window.move({ workspace = "r~5" })'')
            # move window in directions
            (mkBind "SHIFT + h" ''hl.dsp.window.move({ direction = "l" })'')
            (mkBind "SHIFT + l" ''hl.dsp.window.move({ direction = "r" })'')
            (mkBind "SHIFT + k" ''hl.dsp.window.move({ direction = "u" })'')
            (mkBind "SHIFT + j" ''hl.dsp.window.move({ direction = "d" })'')
            # screenshot — freeze, slurp region, copy PNG to clipboard
            {
              _args = [
                (mkLuaInline ''mod .. " + Q"'')
                (mkLuaInline ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-copy" ''
                  p=$(mktemp -u).fifo
                  mkfifo "$p"
                  ${pkgs.wayfreeze}/bin/wayfreeze --after-freeze-timeout 100 --hide-cursor --after-freeze-cmd "echo > $p" & wp=$!
                  read -r < "$p"
                  g=$(${pkgs.slurp}/bin/slurp -d)
                  if [ -z "$g" ]; then kill "$wp" 2>/dev/null; rm -f "$p"; exit 1; fi
                  ${pkgs.grim}/bin/grim -g "$g" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
                  kill "$wp" 2>/dev/null; rm -f "$p"
                ''}")'')
              ];
            }
            # screenshot — same, but save to ~/Pictures/screenshots/
            {
              _args = [
                (mkLuaInline ''mod .. " SHIFT + Q"'')
                (mkLuaInline ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-save" ''
                  filepath="$HOME/Pictures/screenshots/$(date +%Y%m%d-%H%M%S).png"
                  mkdir -p "$(dirname "$filepath")"
                  p=$(mktemp -u).fifo
                  mkfifo "$p"
                  ${pkgs.wayfreeze}/bin/wayfreeze --after-freeze-timeout 100 --hide-cursor --after-freeze-cmd "echo > $p" & wp=$!
                  read -r < "$p"
                  g=$(${pkgs.slurp}/bin/slurp -d)
                  if [ -z "$g" ]; then kill "$wp" 2>/dev/null; rm -f "$p"; exit 1; fi
                  ${pkgs.grim}/bin/grim -g "$g" "$filepath"
                  kill "$wp" 2>/dev/null; rm -f "$p"
                ''}")'')
              ];
            }
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
                (mkLuaInline ''hl.dsp.exec_cmd("hyprctl reload config-only")'')
              ];
            }
            {
              _args = [
                (mkLuaInline ''mod .. " + R"'')
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
