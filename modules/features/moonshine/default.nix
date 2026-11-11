root@{ inputs, ... }:
{
  flake.modules.nixos.moonshine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      script =
        name: text:
        lib.getExe (
          pkgs.writeShellApplication {
            inherit name text;
            runtimeInputs = [
              config.programs.gamescope.package
              config.programs.steam.package
              pkgs.findutils
            ];
          }
        );
    in
    {
      imports = [ inputs.moonshine.nixosModules.default ];

      programs.steam.enable = true;
      programs.gamescope.enable = true;

      # input: virtual pads without a logged-in seat; moonshine: its sleep-inhibit polkit rule
      users.users.${root.config.identity.username}.extraGroups = [
        "input"
        "moonshine"
      ];

      services.moonshine = {
        enable = true;
        # unpatched, one stalled TLS handshake hangs pairing and launches until a restart
        package = (pkgs.callPackage "${inputs.moonshine}/nix/package.nix" { }).overrideAttrs (old: {
          patches = old.patches or [ ] ++ [ ./https-handshake.patch ];
        });
        user = root.config.identity.username;
        settings = {
          name = config.networking.hostName;
          application = [
            {
              title = "Steam";
              # inside gamescope, games see one display at exactly the client's mode
              command = [
                (script "moonshine-steam" ''
                  # games present to gamescope, not past it through the WSI layer
                  export DISABLE_FERRISCOPE_WSI=1
                  # games get their own Xwayland, as on SteamOS: sharing Steam's, they lose X focus to the overlay and minimize for good
                  # the Deck UI, as on SteamOS: Big Picture swaps the base layer across the two Xwaylands and the stream froze on the game
                  exec gamescope --steam -f -b --xwayland-count 2 \
                    -W "$MOONSHINE_CLIENT_WIDTH" -H "$MOONSHINE_CLIENT_HEIGHT" \
                    -w "$MOONSHINE_CLIENT_WIDTH" -h "$MOONSHINE_CLIENT_HEIGHT" \
                    -r "$MOONSHINE_CLIENT_FRAMERATE" \
                    -- steam -gamepadui
                '')
              ];
              # Steam is single-instance: a desktop Steam would swallow the stream's launch
              pre_command = [
                [
                  (script "moonshine-steam-close" ''
                    # steam.sh's own check: the pid holds steam.pipe open, so a recycled pid doesn't count
                    steam_running() {
                      local pid
                      pid=$(cat "$HOME/.steam/steam.pid" 2>/dev/null) || return 1
                      [ -n "$(find "/proc/$pid/fd" -lname "$HOME/.steam/steam.pipe" -print -quit 2>/dev/null)" ]
                    }
                    steam_running || exit 0
                    steam -shutdown
                    tries=30
                    while steam_running; do
                      ((--tries)) || { echo "desktop Steam did not shut down" >&2; exit 1; }
                      sleep 1
                    done
                  '')
                ]
              ];
              stdout = "journal";
              stderr = "journal";
            }
          ];
        };
      };
    };
}
