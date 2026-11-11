root: {
  flake.modules.nixos.game-mode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.gameMode) output;
      session = lib.getExe (
        pkgs.writeShellApplication {
          name = "game-mode-session";
          runtimeInputs = [
            config.programs.gamescope.package
            config.programs.steam.package
          ];
          # games get their own Xwayland, as on SteamOS: sharing Steam's, they lose X focus to the overlay and minimize for good
          # the Deck UI, as on SteamOS: Big Picture swaps the base layer across the two Xwaylands and froze the picture on the game
          text = ''
            exec gamescope --steam --prefer-output ${output} -W 3840 -H 2160 -r 60 --xwayland-count 2 \
              -- steam -gamepadui -pipewire-dmabuf
          '';
        }
      );
    in
    {
      options.gameMode.output = lib.mkOption {
        type = lib.types.str;
        example = "DP-3";
        description = "A free connector, forced on with a 4K60 EDID, that gamescope drives and Sunshine captures.";
      };

      config = {
        programs.steam.enable = true;
        programs.gamescope.enable = true;

        hardware.display = {
          edid.modelines."4k60" = "533.00  3840 3888 3920 4000  2160 2163 2168 2222  +hsync -vsync";
          outputs.${output} = {
            edid = "4k60.bin";
            mode = "e";
          };
        };

        services.displayManager.ly.enable = lib.mkForce false;
        services.greetd = {
          enable = true;
          settings = {
            initial_session = {
              user = root.config.identity.username;
              command = session;
            };
            default_session.command = "${lib.getExe' config.services.greetd.package "agreety"} --cmd ${session}";
          };
        };

        # Sunshine's PlayStation, Switch and Xbox One pads need it, and NixOS ignores the package's modules-load.d
        boot.kernelModules = [ "uhid" ];

        services.sunshine = {
          enable = true;
          openFirewall = true;
          capSysAdmin = true;
          settings = {
            capture = "kms";
            encoder = "vaapi";
            output_name = output;
            system_tray = "disabled";
          };
          applications.apps = [
            {
              name = "Steam";
              image-path = "steam.png";
              # KMS capture reads a single plane and misses overlays; Steam resets gamescope's --force-composition, so set it per stream
              prep-cmd = [
                {
                  do = "${lib.getExe pkgs.xprop} -display :0 -root -f GAMESCOPE_COMPOSITE_FORCE 32c -set GAMESCOPE_COMPOSITE_FORCE 1";
                  undo = "";
                }
              ];
            }
          ];
        };

        # gamescope never starts graphical-session.target
        systemd.user.services.sunshine = {
          wantedBy = lib.mkForce [ "default.target" ];
          wants = lib.mkForce [ ];
          partOf = lib.mkForce [ ];
          after = lib.mkForce [ ];
        };
      };
    };
}
