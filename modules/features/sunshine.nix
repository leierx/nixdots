root: {
  flake.modules.nixos.sunshine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      script =
        name: runtimeInputs: text:
        lib.getExe (pkgs.writeShellApplication { inherit name runtimeInputs text; });
      hyprland = [
        config.programs.hyprland.package
        config.systemd.package
        pkgs.jq
      ];
      # streams a headless output at the client's mode, next to the physical ones
      display = {
        do = script "sunshine-display-do" hyprland ''
          # hyprmoncfgd would re-lay the outputs out, hypridle lock the stream
          systemctl --user stop hyprmoncfgd.service hypridle.service
          # a game started from fullscreen Big Picture would otherwise map behind it
          hyprctl eval 'hl.config({ misc = { on_focus_under_fullscreen = "take_over", exit_window_retains_fullscreen = "enable" } })'
          # past the physical outputs with a gap, so the cursor stays on the stream
          x=$(hyprctl monitors -j | jq '[.[] | .x + .width / .scale] | max + 1000 | floor')
          hyprctl eval "hl.monitor({ output = \"SUNSHINE\", mode = \"''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}\", position = \"''${x}x0\", scale = 1 })"
          hyprctl output create headless SUNSHINE
          tries=50
          until hyprctl monitors -j | jq -e 'any(.[]; .name == "SUNSHINE")' >/dev/null; do
            ((--tries)) || { echo "SUNSHINE output did not appear" >&2; exit 1; }
            sleep 0.1
          done
          # new windows open on the focused monitor
          hyprctl dispatch 'hl.dsp.focus({ monitor = "SUNSHINE" })'
        '';
        undo = script "sunshine-display-undo" hyprland ''
          hyprctl output remove SUNSHINE
          # drops the rules above
          hyprctl reload
          # the stream's workspaces are outside every monitor's hyprsplit range
          hyprctl eval 'require("hyprsplit").dsp.grab_rogue_windows()()'
          systemctl --user start hyprmoncfgd.service hypridle.service
        '';
      };
      steam = [
        config.programs.steam.package
        pkgs.findutils
        pkgs.util-linux
      ];
      # steam.sh's own check: the pid holds steam.pipe open, so a recycled pid doesn't count
      steamRunning = ''
        steam_running() {
          local pid
          pid=$(cat "$HOME/.steam/steam.pid" 2>/dev/null) || return 1
          [ -n "$(find "/proc/$pid/fd" -lname "$HOME/.steam/steam.pipe" -print -quit 2>/dev/null)" ]
        }
      '';
    in
    {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        # started by hand: `systemctl --user start sunshine`
        autoStart = false;
        settings = {
          # wlr capture reaches headless outputs, KMS (and capSysAdmin) cannot
          capture = "wlr";
          encoder = "vaapi";
          output_name = "SUNSHINE";
        };
        applications.apps = [
          {
            name = "Desktop";
            prep-cmd = [ display ];
          }
        ]
        ++ lib.optional config.programs.steam.enable {
          name = "Steam Big Picture";
          image-path = "steam.png";
          # runs as long as the Steam client, so quitting Steam ends the stream
          cmd = script "sunshine-steam-open" steam ''
            ${steamRunning}
            # outside the app's process group, so ending the stream shuts Steam down through close, not a kill
            setsid -f steam steam://open/bigpicture
            tries=120
            until steam_running; do
              ((--tries)) || { echo "Steam did not start" >&2; exit 1; }
              sleep 1
            done
            # Steam restarts itself after updates, briefly leaving no client
            while steam_running || { sleep 5; steam_running; }; do
              sleep 2
            done
          '';
          prep-cmd = [
            display
            {
              do = "";
              undo = script "sunshine-steam-close" steam ''
                ${steamRunning}
                if steam_running; then steam -shutdown; fi
              '';
            }
          ];
        };
      };

      # the prep commands drive Hyprland
      systemd.user.services.sunshine = {
        partOf = lib.mkForce [ "hyprland-session.target" ];
        after = lib.mkForce [ "hyprland-session.target" ];
      };

      home-manager.users.${root.config.identity.username}.imports = [
        root.config.flake.modules.homeManager.sunshine
      ];
    };

  # keeps the bar off the stream
  flake.modules.homeManager.sunshine.programs.waybar.settings.topbar.output = "!SUNSHINE";
}
