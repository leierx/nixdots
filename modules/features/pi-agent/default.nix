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
      # the mac has no unstable overlay
      unstablePkgs =
        pkgs.unstable or (import inputs.nixpkgs-unstable {
          inherit (pkgs.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        });
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
        package = unstablePkgs.pi-coding-agent;
        # suffixed so a project shell's git and node win; nixpkgs' wrapper already prefixes rg and fd
        extraPackages = [
          pkgs.git
          pkgs.nodejs
          unstablePkgs.claude-code
          (pkgs.python3.withPackages (ps: [ ps.pyyaml ]))
          pkgs.yq-go
          pkgs.dnsutils
          pkgs.file
          pkgs.openssl
          pkgs.unzip
          pkgs.xxd
        ];
        appendSystem = ./APPEND_SYSTEM.md;
        mutableSettings = true;

        settings = {
          defaultProvider = lib.mkDefault "claude-bridge";
          defaultModel = lib.mkDefault "claude-opus-5-5";
          defaultThinkingLevel = lib.mkDefault "high";
          enableInstallTelemetry = false;
          collapseChangelog = true;
          quietStartup = true;
          hideThinkingBlock = true;
          modelThinkingLevels."github-copilot/claude-opus-5.5" = "high";
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
            "npm:@tintinweb/pi-subagents@0.26.2"
            "npm:@juicesharp/rpiv-ask-user-question@2.15.0"
            "npm:@juicesharp/rpiv-todo@2.15.0"
            # fork for provider.waitForUsageReset until elidickinson/pi-claude-bridge#289 is released
            "git:github.com/leierx/pi-claude-bridge@6f67f622c96de0237888d87c4cd213e393375e2f"
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

        "${cfgDir}/skills/design-board".source = ./skills/design-board;

        "${cfgDir}/claude-bridge.json".text = builtins.toJSON {
          provider.pathToClaudeCodeExecutable = lib.getExe unstablePkgs.claude-code;
          provider.waitForUsageReset = true;
        };

        "${cfgDir}/extensions/bell.ts".source = ./extensions/bell.ts;

        "${cfgDir}/extensions/tmux-session.ts".source = pkgs.replaceVars ./extensions/tmux-session.ts {
          tmux = lib.getExe config.programs.tmux.package;
        };
      };
    };
}
