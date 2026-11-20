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
      inherit (root.config.hyprland) workspaces;

      mkBind =
        {
          key,
          dispatcher,
          # shown by `hyprctl binds`, for keybind menus
          desc,
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
            (opts // { description = desc; })
          ];
        };

      exec = cmd: "hl.dsp.exec_cmd(${builtins.toJSON cmd})";

      wpctl = lib.getExe' osConfig.services.pipewire.wireplumber.package "wpctl";
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
          libnotify
          xdg-utils
        ];
        text = ''
          screenshot_dir=${lib.escapeShellArg "${config.xdg.userDirs.pictures}/screenshots"}
        ''
        + builtins.readFile ./scripts/freeze-region.sh;
      };

      directions = {
        h = {
          dir = "l";
          name = "left";
        };
        l = {
          dir = "r";
          name = "right";
        };
        k = {
          dir = "u";
          name = "up";
        };
        j = {
          dir = "d";
          name = "down";
        };
      };
    in
    {
      # The control centre takes a screenshot by name too.
      home.packages = [ freezeRegion ];

      wayland.windowManager.hyprland = {
        settings.bind = [
          (mkBind {
            key = "mouse:272";
            dispatcher = "hl.dsp.window.drag()";
            desc = "Move window";
            opts.mouse = true;
          })
          (mkBind {
            key = "mouse:273";
            dispatcher = "hl.dsp.window.resize()";
            desc = "Resize window";
            opts.mouse = true;
          })
          (mkBind {
            key = "Return";
            dispatcher = exec (lib.getExe config.programs.wezterm.package);
            desc = "Terminal";
          })
          (mkBind {
            key = "w";
            dispatcher = "hl.dsp.window.close()";
            desc = "Close window";
          })
          (mkBind {
            key = "s";
            dispatcher = ''hl.dsp.window.float({ action = "toggle" })'';
            desc = "Toggle floating";
          })
          (mkBind {
            key = "f";
            dispatcher = "hl.dsp.window.fullscreen()";
            desc = "Fullscreen";
          })
          (mkBind {
            key = "m";
            dispatcher = "hl.dsp.window.fullscreen({ mode = 1 })";
            desc = "Maximize";
          })
          (mkBind {
            key = "o";
            dispatcher = ''hl.dsp.focus({ monitor = "+1" })'';
            desc = "Focus next monitor";
          })
          (mkBind {
            key = "o";
            modifiers = [ "SHIFT" ];
            dispatcher = ''hl.dsp.window.move({ monitor = "+1" })'';
            desc = "Move window to next monitor";
          })
          (mkBind {
            key = "c";
            dispatcher = ''
              function()
                hl.dispatch(hl.dsp.window.cycle_next())
                hl.dispatch(hl.dsp.window.bring_to_top())
              end'';
            desc = "Cycle windows";
          })
          (mkBind {
            key = "Q";
            dispatcher = exec "${lib.getExe freezeRegion} copy";
            desc = "Screenshot region to clipboard";
          })
          (mkBind {
            key = "Q";
            modifiers = [ "SHIFT" ];
            dispatcher = exec "${lib.getExe freezeRegion} save";
            desc = "Screenshot region to file";
          })
        ]
        ++ lib.concatMap (
          n:
          let
            key = toString n;
          in
          [
            (mkBind {
              inherit key;
              dispatcher = "hs.dsp.focus({ workspace = ${key} })";
              desc = "Focus workspace ${key}";
            })
            (mkBind {
              inherit key;
              modifiers = [ "SHIFT" ];
              dispatcher = "hs.dsp.window.move({ workspace = ${key}, follow = false })";
              desc = "Move window to workspace ${key}";
            })
          ]
        ) (lib.range 1 workspaces)
        ++ lib.concatLists (
          lib.mapAttrsToList (
            key:
            { dir, name }:
            [
              (mkBind {
                inherit key;
                dispatcher = ''hl.dsp.focus({ direction = "${dir}" })'';
                desc = "Focus ${name}";
              })
              (mkBind {
                inherit key;
                modifiers = [ "SHIFT" ];
                dispatcher = ''hl.dsp.window.move({ direction = "${dir}" })'';
                desc = "Move window ${name}";
              })
            ]
          ) directions
        )
        ++ lib.concatLists (
          lib.mapAttrsToList
            (
              key:
              {
                cmd,
                desc,
                repeating,
                osd ? null,
              }:
              [
                (mkBind {
                  inherit key desc;
                  withMod = false;
                  dispatcher = exec cmd;
                  opts = {
                    locked = true;
                  }
                  // lib.optionalAttrs repeating { inherit repeating; };
                })
              ]
              # the OSD shows a level at its end too; a bind of its own, as Hyprland reruns a global's bind on release
              ++ lib.optional (osd != null) (mkBind {
                inherit key;
                withMod = false;
                dispatcher = ''hl.dsp.global("quickshell:osd-${osd}")'';
                desc = "Show ${osd}";
              })
            )
            {
              XF86AudioRaiseVolume = {
                cmd = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
                desc = "Volume up";
                repeating = true;
                osd = "volume";
              };
              XF86AudioLowerVolume = {
                cmd = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                desc = "Volume down";
                repeating = true;
                osd = "volume";
              };
              XF86AudioMute = {
                cmd = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                desc = "Mute";
                repeating = false;
              };
              XF86AudioMicMute = {
                cmd = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                desc = "Mute microphone";
                repeating = false;
              };
              XF86MonBrightnessUp = {
                cmd = "${brightnessctl} set 5%+";
                desc = "Brightness up";
                repeating = true;
                osd = "brightness";
              };
              XF86MonBrightnessDown = {
                cmd = "${brightnessctl} set 5%-";
                desc = "Brightness down";
                repeating = true;
                osd = "brightness";
              };
              XF86AudioPlay = {
                cmd = "${playerctl} play-pause";
                desc = "Play/pause";
                repeating = false;
              };
              XF86AudioPause = {
                cmd = "${playerctl} play-pause";
                desc = "Play/pause";
                repeating = false;
              };
              XF86AudioNext = {
                cmd = "${playerctl} next";
                desc = "Next track";
                repeating = false;
              };
              XF86AudioPrev = {
                cmd = "${playerctl} previous";
                desc = "Previous track";
                repeating = false;
              };
            }
        );
      };
    };
}
