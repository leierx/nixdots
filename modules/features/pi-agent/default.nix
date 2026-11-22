{ inputs, ... }:
{
  flake.modules.homeManager.pi-agent =
    {
      config,
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    let
      cfgDir = config.programs.pi-coding-agent.configDir;
      # drop when github:nix-community/home-manager/release-26.11 ships programs.pi-coding-agent
      piCodingAgentModule =
        args@{
          config,
          pkgs,
          lib,
          ...
        }:
        let
          hmUnstableLib = import "${inputs.home-manager-unstable}/modules/lib" { inherit lib; };
        in
        import "${inputs.home-manager-unstable}/modules/programs/pi-coding-agent.nix" (
          args
          // {
            lib = lib.extend (
              _: super: {
                hm = super.hm // hmUnstableLib;
                maintainers = super.maintainers // hmUnstableLib.maintainers;
              }
            );
          }
        );
    in
    {
      imports = lib.optional (
        !builtins.pathExists "${modulesPath}/programs/pi-coding-agent.nix"
      ) piCodingAgentModule;

      programs.pi-coding-agent = {
        enable = true;
        package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent;
        # suffixed so a project shell's git and node win; nixpkgs' wrapper already prefixes rg and fd
        extraPackages = [
          pkgs.git
          pkgs.nodejs
        ];
        appendSystem = ./APPEND_SYSTEM.md;
        mutableSettings = true;

        settings = {
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
        };

        # DeepSeek's agentic evals; its API ignores temperature in thinking mode, other hosts may not
        models.providers.opencode-go.modelOverrides."deepseek-v4.1-flash".samplingParams = {
          temperature = 1.0;
          top_p = 0.95;
        };
      };

      home.file = {
        "${cfgDir}/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;

        "${cfgDir}/extensions/bell.ts".source = ./extensions/bell.ts;

        "${cfgDir}/extensions/tmux-session.ts".source = pkgs.replaceVars ./extensions/tmux-session.ts {
          tmux = lib.getExe config.programs.tmux.package;
        };
      };
    };
}
