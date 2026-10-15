root: {
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.generators) mkLuaInline;
      inherit (root.config.hyprland) workspaces;

      mkBind =
        {
          key,
          dispatcher,
          modifiers ? [ ],
          withMod ? true,
          opts ? { },
        }:
        let
          keys = lib.concatStringsSep " + " (modifiers ++ [ key ]);
        in
        {
          _args = [
            (if withMod then mkLuaInline ''mod .. " + ${keys}"'' else keys)
            (mkLuaInline dispatcher)
          ]
          ++ lib.optional (opts != { }) opts;
        };

      exec = cmd: "hl.dsp.exec_cmd(${builtins.toJSON cmd})";

      rofi = lib.getExe config.programs.rofi.finalPackage;
      cliphist = lib.getExe config.services.cliphist.package;
      wpctl = lib.getExe' pkgs.wireplumber "wpctl";
      brightnessctl = lib.getExe pkgs.brightnessctl;
      playerctl = lib.getExe pkgs.playerctl;

      freezeRegion = pkgs.writeShellApplication {
        name = "freeze-region";
        runtimeInputs = with pkgs; [
          wayfreeze
          slurp
          grim
          wl-clipboard
          coreutils
        ];
        text = ''
          screenshot_dir=${lib.escapeShellArg "${config.xdg.userDirs.pictures}/screenshots"}
        ''
        + builtins.readFile ./scripts/freeze-region.sh;
      };

      directions = {
        h = "l";
        l = "r";
        k = "u";
        j = "d";
      };
    in
    {
      wayland.windowManager.hyprland = {
        settings.bind = [
          # mouse
          (mkBind {
            key = "mouse:272";
            dispatcher = "hl.dsp.window.drag()";
            opts.mouse = true;
          })
          (mkBind {
            key = "mouse:273";
            dispatcher = "hl.dsp.window.resize()";
            opts.mouse = true;
          })
          # launchers
          (mkBind {
            key = "Return";
            dispatcher = exec (lib.getExe config.programs.wezterm.package);
          })
          (mkBind {
            key = "d";
            dispatcher = exec "${rofi} -modes drun -show drun";
          })
          (mkBind {
            key = "b";
            dispatcher = exec "${cliphist} list | ${rofi} -dmenu -display-columns 2 -theme-str 'window {width: 50%;height: 75%;} entry {placeholder: \"Clipboard\";}' | ${cliphist} decode | ${lib.getExe' config.services.cliphist.clipboardPackage "wl-copy"}";
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
          # screenshot a frozen region (SHIFT: save instead of copy)
          (mkBind {
            key = "Q";
            dispatcher = exec "${lib.getExe freezeRegion} copy";
          })
          (mkBind {
            key = "Q";
            modifiers = [ "SHIFT" ];
            dispatcher = exec "${lib.getExe freezeRegion} save";
          })
          # system_control submap, left again after 2 s
          (mkBind {
            key = "X";
            dispatcher = ''
              function()
                hl.dispatch(hl.dsp.submap("system_control"))
                hl.timer(function() hl.dispatch(hl.dsp.submap("reset")) end,
                         { timeout = 2000, type = "oneshot" })
              end'';
          })
        ]
        # workspaces on the focused monitor, through hyprsplit
        ++ lib.concatMap (
          n:
          let
            key = toString n;
          in
          [
            (mkBind {
              inherit key;
              dispatcher = "hs.dsp.focus({ workspace = ${key} })";
            })
            (mkBind {
              inherit key;
              modifiers = [ "SHIFT" ];
              dispatcher = "hs.dsp.window.move({ workspace = ${key}, follow = false })";
            })
          ]
        ) (lib.range 1 workspaces)
        # focus / move in a direction
        ++ lib.concatLists (
          lib.mapAttrsToList (key: dir: [
            (mkBind {
              inherit key;
              dispatcher = ''hl.dsp.focus({ direction = "${dir}" })'';
            })
            (mkBind {
              inherit key;
              modifiers = [ "SHIFT" ];
              dispatcher = ''hl.dsp.window.move({ direction = "${dir}" })'';
            })
          ]) directions
        )
        # media and brightness keys, also on the lockscreen
        ++
          lib.mapAttrsToList
            (
              key:
              { cmd, repeating }:
              mkBind {
                inherit key;
                withMod = false;
                dispatcher = exec cmd;
                opts = {
                  locked = true;
                }
                // lib.optionalAttrs repeating { inherit repeating; };
              }
            )
            {
              XF86AudioRaiseVolume = {
                cmd = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
                repeating = true;
              };
              XF86AudioLowerVolume = {
                cmd = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                repeating = true;
              };
              XF86AudioMute = {
                cmd = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                repeating = false;
              };
              XF86AudioMicMute = {
                cmd = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                repeating = false;
              };
              XF86MonBrightnessUp = {
                cmd = "${brightnessctl} set 5%+";
                repeating = true;
              };
              XF86MonBrightnessDown = {
                cmd = "${brightnessctl} set 5%-";
                repeating = true;
              };
              XF86AudioPlay = {
                cmd = "${playerctl} play-pause";
                repeating = false;
              };
              XF86AudioPause = {
                cmd = "${playerctl} play-pause";
                repeating = false;
              };
              XF86AudioNext = {
                cmd = "${playerctl} next";
                repeating = false;
              };
              XF86AudioPrev = {
                cmd = "${playerctl} previous";
                repeating = false;
              };
            };

        submaps.system_control = {
          onDispatch = "reset"; # auto-exits the submap after any dispatch
          settings.bind = [
            # shut down
            {
              _args = [
                "ESCAPE"
                (mkLuaInline (exec "systemctl poweroff"))
              ];
            }
            # exit hyprland
            {
              _args = [
                "Q"
                (mkLuaInline "hl.dsp.exit()")
              ];
            }
            # reload the config
            {
              _args = [
                "R"
                (mkLuaInline (exec "hyprctl reload"))
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
