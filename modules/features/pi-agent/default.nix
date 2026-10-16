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
          # nixpkgs' wrapper already prefixes ripgrep and fd; git (worktrees, commits) and node
          # (npm install scripts) are suffixed so project shells win
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

              # herdr drops its integration here; it is not wanted by default
              extensions = [ "!extensions/herdr-*" ];

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
                "npm:@tintinweb/pi-subagents@0.22.0"
                "npm:@juicesharp/rpiv-ask-user-question@2.13.8"
                "npm:@juicesharp/rpiv-todo@2.13.8"
              ];
            } config.piAgent.settings
          );

          ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

          ".pi/agent/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;
        };
      };
    };
}
