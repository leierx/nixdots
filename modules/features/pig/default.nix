root: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pig = pkgs.buildGo127Module (finalAttrs: {
        pname = "pig";
        version = "0.4.1";

        src = pkgs.fetchFromGitHub {
          owner = "MichaelKinsy";
          repo = "PiG";
          tag = "v${finalAttrs.version}";
          hash = "sha256-JmsDIQMIfIr6StkLO7IJPajenJfOotYuZ0ZZCYVzMeA=";
        };

        vendorHash = "sha256-aEMyg5U1qkxCrKeXyV6Uu9mlozGTi8QUIbWA6I1GWis=";

        subPackages = [ "cmd/pig" ];

        # Build from go.mod alone; go.work would swap the tagged extensions/sdk for the in-tree copy.
        env = {
          GOWORK = "off";
          CGO_ENABLED = 0;
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Build=v${finalAttrs.version}"
          "-X github.com/MichaelKinsy/PiG/coding/pigletbuild.releaseSourceVersion=v${finalAttrs.version}"
        ];

        # The suite needs tmux, pty, Node and network access.
        doCheck = false;

        meta = {
          description = "Pi coding agent ported to Go";
          homepage = "https://github.com/MichaelKinsy/PiG";
          license = pkgs.lib.licenses.mit;
          mainProgram = "pig";
        };
      });
    };

  flake.modules.homeManager.pig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # PiG's root is $XDG_CONFIG_HOME/pig when set, which xdg.enable exports; ~/.pig otherwise
      agentDir = if config.xdg.enable then "${config.xdg.configHome}/pig/agent" else ".pig/agent";
    in
    {
      options.pig.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.json;
        default = { };
        description = ''
          Overrides for PiG's settings.json, merged over the defaults
          in pig/default.nix; e.g. pin a default provider, model or thinking level.
        '';
      };

      config = {
        # PiG's own fd download for Linux is glibc-linked and won't run on NixOS
        programs.ripgrep.enable = true;
        programs.fd.enable = true;

        home = {
          packages = [
            root.config.flake.packages.${pkgs.stdenv.hostPlatform.system}.pig
            # runs the TypeScript plugins
            pkgs.nodejs
          ];

          sessionVariables.PI_SKIP_VERSION_CHECK = "1";

          file = {
            "${agentDir}/settings.json".source = (pkgs.formats.json { }).generate "pig-settings.json" (
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
                  "npm:pi-subagents@0.78.0"
                  "npm:@juicesharp/rpiv-ask-user-question@2.13.8"
                  "npm:@juicesharp/rpiv-todo@2.13.8"
                ];
              } config.pig.settings
            );

            "${agentDir}/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

            "${agentDir}/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;
          };
        };
      };
    };
}
