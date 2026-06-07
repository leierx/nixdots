{ config, inputs, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.sharedModules = [ outerConfig.modules.homeManager.hyprland ];
    };

  modules.homeManager.hyprland =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        outerConfig.modules.homeManager.wezterm
        outerConfig.modules.homeManager.rofi
      ];

      home.packages = [ pkgs.wl-clipboard ];

      wayland.windowManager.hyprland = {
        enable = true;
        package = osConfig.programs.hyprland.package;
        portalPackage = osConfig.programs.hyprland.portalPackage;
        settings = {
          general = {
            border_size = 2;
            gaps_in = 10;
            gaps_out = 15;
            col = {
              inactive_border = "rgb(595959)";
              active_border = {
                colors = [
                  "rgb(2bbf3e)"
                  "rgb(2bbf3e)"
                  "rgb(2bbf3e)"
                  "rgb(0e66d0)"
                  "rgb(0e66d0)"
                  "rgb(0e66d0)"
                ];
                angle = 30;
              };
              nogroup_border = "0xffffaaff";
              nogroup_border_active = "0xffff00ff";
            };
            layout = "dwindle"; # default layout
          };

          decoration = {
            rounding = 10;
            glow.enabled = false;
            blur.enabled = false;

            shadow = {
              enabled = true;
              range = 40;
              # render_power = 3;
              color = "rgba(0, 0, 0, 0.9)";
            };
          };

          animations.enabled = true;

          gestures = {
            workspace_swipe_create_new = false;
            workspace_swipe_use_r = true;
            scrolling = { }; # default
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            font_family = "Sans";
            force_default_wallpaper = 0;
            disable_autoreload = true;
            focus_on_activate = true;
            background_color = "0x1C1C1C";
            on_focus_under_fullscreen = 0;
            middle_click_paste = false;
          };

          binds.workspace_back_and_forth = true; # intresting feature!

          xwayland.enabled = true;

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
            enforce_permissions = false; # I want to eventually! its a cool feature
          };

          dwindle.force_split = 2;

          # Programs to launch every time Hyprland starts (re-run on reload).
          exec = [
            # "swww init"
          ];

          exec-once = [
            "${lib.getExe pkgs.wbg} ${./assets/wallpaper.png}" # wallpaper
            "vesktop"
            "firefox --new-window"
          ];
          on._args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("uwsm finalize")
              end
            '')
          ];

          # Run a raw command (no shell wrapper) every reload.
          execr = [ ];

          # Run a raw command (no shell wrapper) once at startup.
          execr-once = [ ];

          # Programs to run when Hyprland shuts down.
          exec-shutdown = [ ];

          # Monitor configuration. Format:
          #   "NAME,RESOLUTION@RATE,POSITION,SCALE[,additional...]"
          # Use ",preferred,auto,1" as a generic fallback rule.
          monitor = [
            ",preferred,auto,1"
          ];

          # Environment variables exported to the session. Format: "KEY,VALUE".
          env = [
            # "XCURSOR_SIZE,24"
            # "QT_QPA_PLATFORMTHEME,qt5ct"
          ];

          # Keybinds. Format: "MODS, KEY, dispatcher, args"
          # Bind flags can be appended after the b: e.g. "binde", "bindm" (mouse),
          # "bindr" (release), "bindl" (locked), "binds" (silent), "bindo"
          # (operating-in-fullscreen), "bindi" (ignore mods), "bindn" (no mods),
          # "bindp" (pass through), "bindc" (click), "bindg" (group).
          bind = [
            # screenshot — freeze, slurp region, copy PNG to clipboard
            {
              _args = [
                "SUPER + Q"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-copy" ''
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
                "SUPER + SHIFT + Q"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${pkgs.writeShellScript "freeze-region-save" ''
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
          ];

          # Explicitly unbind a key.
          unbind = [ ];

          # Per-workspace rules. Format: "WORKSPACE_ID_OR_NAME, rule1, rule2, ..."
          workspace = [ ];

          # Window rules (v3 / unified). Format: "RULE, MATCHER" or with the
          # newer named-property syntax. See wiki for full list of properties
          # (float, tile, opacity, monitor, workspace, size, move, center, ...).
          windowrule = [ ];

          # Layer rules. Format: "RULE, NAMESPACE_REGEX".
          layerrule = [ ];

          # Custom bezier curves for animations. Format: "name, x1, y1, x2, y2"
          bezier = [
            # "myBezier, 0.05, 0.9, 0.1, 1.05"
          ];

          # Animation overrides. Format:
          #   "NAME, ON/OFF, DURATION_IN_DS, BEZIER_NAME [, STYLE]"
          # DURATION is in deciseconds (1ds = 100ms).
          animation = [
            # "windows,    1, 7, myBezier"
            # "windowsOut, 1, 7, default, popin 80%"
            # "border,     1, 10, default"
            # "fade,       1, 7, default"
            # "workspaces, 1, 6, default"
          ];

          # Submaps — modal binding contexts. Use the `submap` dispatcher to
          # enter one. With `settings`, you typically just declare the names
          # and put binds inside a raw `extraConfig` block, since hyprlang's
          # submap syntax is positional.
          submap = [ ];

          # Plugin paths (.so files) to load.
          plugin = [ ];

          # Permission rules. Format: "REGEX, CAPABILITY, MODE".
          permission = [ ];

          # Touchpad gestures. Format follows the wiki's `gesture =` syntax,
          # e.g. "3, horizontal, workspace".
          gesture = [ ];
        };

        # If you have anything that doesn't fit the structured `settings`
        # above (raw hyprlang blocks like `submap = NAME { ... }`), put it
        # here.
        extraConfig = "";
      };
    };
}
