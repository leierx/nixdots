{ inputs, ... }:
{
  flake.modules.homeManager.pi-agent =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.piAgent.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.json;
        default = { };
        description = ''
          Overrides for ~/.pi/agent/settings.json, merged over the defaults
          in pi-agent/default.nix; e.g. pin a default provider, model or thinking level.
        '';
      };

      config.home = {
        packages = [
          # suffixed so a project shell's git and node win; nixpkgs' wrapper already prefixes rg and fd
          (pkgs.symlinkJoin {
            name = "pi-wrapped";
            paths = [
              inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent
            ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/pi --suffix PATH : ${
                lib.makeBinPath [
                  pkgs.git
                  pkgs.nodejs
                ]
              }
            '';
          })
        ];

        file = {
          ".pi/agent/settings.json".source = (pkgs.formats.json { }).generate "pi-settings.json" (
            lib.recursiveUpdate {
              enableInstallTelemetry = false;
              collapseChangelog = true;
              quietStartup = true;
              hideThinkingBlock = true;
              tuiMode = "regular";
              fullscreenScrollbar = "hidden";

              npmCommand = [ (lib.getExe' pkgs.nodejs "npm") ];

              defaultTools = [
                "read"
                "bash"
                "edit"
                "write"
                "grep"
                "find"
                "ls"
              ];

              packages = [
                "npm:@tintinweb/pi-subagents@0.23.1"
                "npm:@juicesharp/rpiv-ask-user-question@2.15.0"
                "npm:@juicesharp/rpiv-todo@2.15.0"
              ];
            } config.piAgent.settings
          );

          ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

          ".pi/agent/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;

          ".pi/agent/extensions/bell.ts".source = ./extensions/bell.ts;

          ".pi/agent/extensions/tmux-session.ts".source = pkgs.replaceVars ./extensions/tmux-session.ts {
            tmux = lib.getExe config.programs.tmux.package;
          };
        };
      };
    };
}
