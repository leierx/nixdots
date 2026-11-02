{ inputs, ... }:
{
  flake.modules.homeManager.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) types;

      # its hyprctl must match the running compositor
      hyprmoncfg =
        inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hyprmoncfg.override
          { hyprland = config.wayland.windowManager.hyprland.package; };

      profilesDir = "${config.xdg.configHome}/hyprmoncfg/profiles";

      outputModule = types.submodule {
        options = {
          make = lib.mkOption { type = types.str; };
          model = lib.mkOption { type = types.str; };
          serial = lib.mkOption { type = types.str; };
          enabled = lib.mkOption {
            type = types.bool;
            default = true;
          };
          mode = lib.mkOption {
            type = types.nullOr (types.strMatching "[0-9]+x[0-9]+@[0-9.]+");
            default = null;
            example = "2560x1440@143.91";
          };
          x = lib.mkOption {
            type = types.int;
            default = 0;
          };
          y = lib.mkOption {
            type = types.int;
            default = 0;
          };
          scale = lib.mkOption {
            type = types.number;
            default = 1;
          };
        };
      };

      # the subset of hyprmoncfg's profile JSON that `hyprmoncfg save` would write
      toProfile =
        name: outputs:
        builtins.toJSON {
          inherit name;
          # the Nix store's mtime, for the TUI's "updated" column
          created_at = "1970-01-01T00:00:00Z";
          updated_at = "1970-01-01T00:00:00Z";
          outputs = map (
            o:
            let
              id = lib.toLower "${o.make}|${o.model}|${o.serial}";
            in
            {
              key = id;
              match_key = id;
              description = "${o.make} ${o.model} ${o.serial}";
              inherit (o)
                make
                model
                serial
                enabled
                x
                y
                scale
                ;
              transform = 0;
            }
            // lib.optionalAttrs (o.mode != null) (
              let
                size = map builtins.fromJSON (builtins.match "([0-9]+)x([0-9]+)@([0-9.]+)" o.mode);
              in
              {
                mode = "${o.mode}Hz";
                width = builtins.elemAt size 0;
                height = builtins.elemAt size 1;
                refresh = builtins.elemAt size 2;
              }
            )
          ) outputs;
          # hyprsplit owns the workspaces
          workspaces.enabled = false;
          exec = "";
        };

      layoutPicker = pkgs.writeShellApplication {
        name = "monitor-layouts";
        runtimeInputs = [
          hyprmoncfg
          config.programs.rofi.finalPackage
          pkgs.jq
          pkgs.libnotify
          pkgs.coreutils
        ];
        text = ''
          profiles_dir=${lib.escapeShellArg profilesDir}
        ''
        + builtins.readFile ./scripts/monitor-layouts.sh;
      };
    in
    {
      options.hyprmoncfg.profiles = lib.mkOption {
        type = types.attrsOf (types.listOf outputModule);
        default = { };
        description = ''
          hyprmoncfg profiles by name, outputs identified by EDID make, model and
          serial as `hyprctl monitors` reports them. hyprmoncfg picks the profile
          enabling the most connected outputs. Saving one from the TUI lasts until
          the next home-manager switch.
        '';
      };

      config = {
        home.packages = [ hyprmoncfg ];

        xdg.configFile = lib.mapAttrs' (
          name: outputs:
          lib.nameValuePair "hyprmoncfg/profiles/${name}.json" {
            text = toProfile name outputs;
            # a TUI save replaces the link with a file; replace it back rather than pile up backups
            force = true;
          }
        ) config.hyprmoncfg.profiles;

        systemd.user.services.hyprmoncfgd = {
          Unit = {
            Description = "Hyprland monitor profile daemon";
            PartOf = [ config.wayland.systemd.target ];
            After = [ config.wayland.systemd.target ];
          };
          Service = {
            ExecStart = lib.getExe' hyprmoncfg "hyprmoncfgd";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install.WantedBy = [ config.wayland.systemd.target ];
        };

        wayland.windowManager.hyprland = {
          # SUPER+P, after Windows' display "Project" switcher
          settings.bind = [
            {
              _args = [
                (lib.generators.mkLuaInline ''mod .. " + P"'')
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON (lib.getExe layoutPicker)})")
                { description = "Monitor layouts"; }
              ];
            }
          ];

          # hyprland.lua is read-only, so hyprmoncfg can't append its include; it must be the last line
          extraConfig = lib.mkAfter ''
            do local path = "${config.xdg.configHome}/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
          '';
        };
      };
    };
}
