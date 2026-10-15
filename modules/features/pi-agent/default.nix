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

      # tools pi's bash tool should always find, on pi's PATH only
      config.home.packages = [
        (pkgs.symlinkJoin {
          name = "pi-wrapped";
          paths = [
            inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/pi \
              --prefix PATH : ${
                lib.makeBinPath (
                  with pkgs;
                  [
                    ripgrep
                    fd
                    nodejs
                    bun
                    uv
                    python3
                    jq
                    git
                    coreutils
                    gnumake
                    shellcheck
                    shfmt
                  ]
                )
              } \
              --set-default PI_SKIP_VERSION_CHECK 1
          '';
        })
      ];

      config.home.file = {
        ".pi/agent/settings.json".source = (pkgs.formats.json { }).generate "pi-settings.json" (
          lib.recursiveUpdate {
            enableInstallTelemetry = false;
            collapseChangelog = true;
            quietStartup = true;
            hideThinkingBlock = true;

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
              "npm:pi-subagents@0.72.0"
              "npm:@juicesharp/rpiv-ask-user-question@2.12.0"
              "npm:@juicesharp/rpiv-todo@2.12.0"
            ];
          } config.piAgent.settings
        );

        ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

        ".pi/agent/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;
      };
    };
}
