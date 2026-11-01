{
  flake.modules.nixos.sunshine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # streams a headless output at the client's mode, the only screen while it lasts
      virtualDisplay = pkgs.writeShellApplication {
        name = "sunshine-virtual-display";
        runtimeInputs = [
          config.programs.hyprland.package
          config.systemd.package
          pkgs.jq
        ];
        text = ''
          case "''${1:-}" in
          do)
            # hyprmoncfgd would re-lay the outputs out, hypridle lock the stream, waybar sit on it
            systemctl --user stop hyprmoncfgd.service hypridle.service waybar.service
            # a game started from fullscreen Big Picture would otherwise map behind it
            hyprctl eval 'hl.config({ misc = { on_focus_under_fullscreen = "take_over", exit_window_retains_fullscreen = "enable" } })'
            hyprctl eval "hl.monitor({ output = \"SUNSHINE\", mode = \"''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}\", position = \"auto\", scale = 1 })"
            hyprctl output create headless SUNSHINE
            for output in $(hyprctl monitors -j | jq -r '.[].name | select(. != "SUNSHINE")'); do
              hyprctl eval "hl.monitor({ output = \"$output\", disabled = true })"
            done
            ;;
          undo)
            # drops the rules above, bringing the outputs back; hyprmoncfgd then re-applies its profile
            hyprctl reload
            tries=50
            until hyprctl monitors -j | jq -e 'any(.[]; .name != "SUNSHINE")' >/dev/null; do
              tries=$((tries - 1))
              [ "$tries" -gt 0 ] || { echo "no output besides SUNSHINE after reload" >&2; exit 1; }
              sleep 0.1
            done
            hyprctl output remove SUNSHINE
            # the stream's workspaces are outside every monitor's hyprsplit range
            hyprctl eval 'require("hyprsplit").dsp.grab_rogue_windows()()'
            systemctl --user start hyprmoncfgd.service hypridle.service waybar.service
            ;;
          *)
            echo "usage: sunshine-virtual-display do|undo" >&2
            exit 2
            ;;
          esac
        '';
      };
      display = {
        do = "${lib.getExe virtualDisplay} do";
        undo = "${lib.getExe virtualDisplay} undo";
      };
      steam = lib.getExe config.programs.steam.package;
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
          detached = [ "${steam} steam://open/bigpicture" ];
          prep-cmd = [
            display
            {
              do = "";
              undo = "${steam} -shutdown";
            }
          ];
        };
      };

      # the prep commands drive Hyprland
      systemd.user.services.sunshine = {
        partOf = lib.mkForce [ "hyprland-session.target" ];
        after = lib.mkForce [ "hyprland-session.target" ];
      };
    };
}
