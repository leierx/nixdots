{ config, inputs, ... }:
let
  outerConfig = config;
in
{
  modules.nixos.mango =
    { pkgs, ... }:
    {
      imports = [ inputs.mangowc.nixosModules.mango ];

      # https://github.com/mangowm/mango/blob/main/nix/nixos-modules.nix
      programs.mango = {
        enable = true;
        addLoginEntry = true;
      };

      services.gvfs.enable = true;
      services.gnome.sushi.enable = true;
      environment.systemPackages = [ pkgs.nautilus ];

      home-manager.sharedModules = [ outerConfig.modules.homeManager.mango ];
    };

  modules.homeManager.mango =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    {
      imports = [
        inputs.mangowc.hmModules.mango
        outerConfig.modules.homeManager.wezterm
        outerConfig.modules.homeManager.rofi
      ];

      home.packages = [ pkgs.wl-clipboard ];

      # https://mangowm.github.io/docs/nix-options
      wayland.windowManager.mango = {
        enable = true;
        systemd.enable = true;

        settings = {
          # ─── Input ──────────────────────────────────────────────────────────
          xkb_rules_layout = "no";
          xkb_rules_variant = "nodeadkeys";

          # focus & input — https://mangowm.github.io/docs/configuration/miscellaneous#focus--input
          drag_tile_to_tile = 1;
          exchange_cross_monitor = 1;

          # ─── Layout ─────────────────────────────────────────────────────────
          new_is_master = 0;
          default_mfact = 0.5;
          smartgaps = 1;
          warpcursor = 0;

          # gaps: inner horizontal/vertical, outer horizontal/vertical
          gappih = 10;
          gappiv = 10;
          gappoh = 15;
          gappov = 15;

          # ─── Borders & radius ──────────────────────────────────────────────
          borderpx = 2;
          border_radius = 10;
          no_border_when_single = 1; # might move to a windowrule eventually
          no_radius_when_single = 1; # ditto

          # ─── Window effects ─────────────────────────────────────────────────
          blur = 0; # blur (off)
          blur_layer = 0;

          # shadows (floating only)
          shadows = 1;
          layer_shadows = 1;
          shadow_only_floating = 1;
          shadows_size = 12;
          shadows_blur = 15;
          shadows_position_x = 0;
          shadows_position_y = 0;
          shadowscolor = "0x000000E6"; # black @ 90%

          # animations (off)
          animations = 0;
          layer_animations = 0;

          # ─── Cursor ─────────────────────────────────────────────────────────
          cursor_size = 24;
          cursor_theme = "Adwaita";

          # ─── Colors ─────────────────────────────────────────────────────────
          # base
          rootcolor = "0x1c1c1cff"; # rofi bg1
          bordercolor = "0x595959ff"; # rofi unfocusedBorderColor
          focuscolor = "0x0e66d0ff"; # rofi focusedBorderColor / primaryColor

          # tiling hints
          dropcolor = "0xd98240dd"; # mellow orange with alpha — drop hint
          splitcolor = "0x4bb0e3ff"; # cyan — related to focus blue, distinct

          # window states
          maximizescreencolor = "0x4fc0f7ff"; # cyanLight — focus, but more
          urgentcolor = "0xf13a31ff"; # rofi red
          scratchpadcolor = "0x9c48ccff"; # magenta — floaty, off to the side
          globalcolor = "0xf1c50fff"; # yellow — unmistakable when it appears
          overlaycolor = "0x2bbf3eff"; # green — pops against the blue-heavy rest

          # ─── Autostart (compositor-managed) ─────────────────────────────────
          exec-once = [
            "${lib.getExe pkgs.wbg} ${./assets/wallpaper.png}" # wallpaper
            "vesktop"
            "firefox --new-window"
          ]
          ++ lib.optional osConfig.networking.networkmanager.enable "${lib.getExe pkgs.networkmanagerapplet}";

          # ─── Window rules ───────────────────────────────────────────────────
          windowrule = [
            "tags:1,monitor:DP-2,isopensilent:1,appid:vesktop"
            "tags:1,monitor:DP-1,isopensilent:1,appid:firefox"
          ];

          # ─── Layer rules ────────────────────────────────────────────────────
          layerrule = [
            "noshadow:1,layer_name:rofi"
          ];

          # ─── Keybinds ───────────────────────────────────────────────────────
          bind = [
            # launchers
            "SUPER,Return,spawn,wezterm"
            "SUPER,D,spawn,rofi -show drun"

            # window state
            "SUPER,w,killclient"
            "SUPER,s,togglefloating"
            "SUPER,f,togglefullscreen"

            # focus direction (hjkl)
            "SUPER,h,focusdir,left"
            "SUPER,j,focusdir,down"
            "SUPER,k,focusdir,up"
            "SUPER,l,focusdir,right"

            # move/swap window direction (hjkl)
            "SUPER+SHIFT,h,exchange_client,left"
            "SUPER+SHIFT,j,exchange_client,down"
            "SUPER+SHIFT,k,exchange_client,up"
            "SUPER+SHIFT,l,exchange_client,right"

            # cycle / swap within stack
            "SUPER,C,focusstack,next"
            "SUPER+SHIFT,C,exchange_stack_client,next"

            # tag (workspace) view
            "SUPER,1,view,1"
            "SUPER,2,view,2"
            "SUPER,3,view,3"
            "SUPER,4,view,4"
            "SUPER,5,view,5"

            # move window to tag (silent)
            "SUPER+SHIFT,1,tagsilent,1"
            "SUPER+SHIFT,2,tagsilent,2"
            "SUPER+SHIFT,3,tagsilent,3"
            "SUPER+SHIFT,4,tagsilent,4"
            "SUPER+SHIFT,5,tagsilent,5"

            # monitors (directional, not cyclic)
            "SUPER,O,focusmon,right"
            "SUPER+SHIFT,O,tagmon,right"

            # session
            "SUPER+SHIFT,R,reload_config"
            "SUPER+SHIFT,E,quit"

            # screenshot — freeze, slurp region, copy PNG to clipboard
            "SUPER,Q,spawn,${pkgs.writeShellScript "freeze-region-copy" ''
              p=$(mktemp -u).fifo
              mkfifo "$p"
              ${pkgs.wayfreeze}/bin/wayfreeze --after-freeze-timeout 100 --hide-cursor --after-freeze-cmd "echo > $p" & wp=$!
              read -r < "$p"
              g=$(${pkgs.slurp}/bin/slurp -d)
              if [ -z "$g" ]; then kill "$wp" 2>/dev/null; rm -f "$p"; exit 1; fi
              ${pkgs.grim}/bin/grim -g "$g" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
              kill "$wp" 2>/dev/null; rm -f "$p"
            ''}"

            # screenshot — same, but save to ~/Pictures/screenshots/
            "SUPER+SHIFT,Q,spawn,${pkgs.writeShellScript "freeze-region-save" ''
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
            ''}"
          ];

          # ─── Mouse ──────────────────────────────────────────────────────────
          mousebind = [
            "SUPER,btn_left,moveresize,curmove" # was: bindm mouse:272 movewindow
            "SUPER,btn_right,moveresize,curresize" # was: bindm mouse:273 resizewindow
          ];

          # things to revisit:
          # - https://mangowm.github.io/docs/configuration/monitors#graphics-card-compatibility
          # - https://mangowm.github.io/docs/configuration/xdg-portals#clipboard-manager
        };
        extraConfig = ""; # lib.types.lines
        topPrefixes = [ ]; # lib.types.listOf str
        bottomPrefixes = [ ]; # lib.types.listOf str
        autostart_sh = "";
      };
    };
}
