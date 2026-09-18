root@{ inputs, ... }:
{
  options.piAgent.settings = root.lib.mkOption {
    type = root.lib.types.attrsOf root.lib.types.json;
    default = { };
    description = ''
      Per-host overrides for ~/.pi/agent/settings.json, merged over the defaults
      in pi-agent/default.nix; e.g. pin a default provider, model or thinking level.
    '';
  };

  config.flake.modules.homeManager.pi-agent =
    { pkgs, lib, ... }:
    {
      home.packages = [
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
                  [
                    pkgs.ripgrep
                    pkgs.fd
                    pkgs.nodejs
                    pkgs.bun
                    pkgs.uv
                    pkgs.python3
                    pkgs.jq
                    pkgs.git
                    pkgs.coreutils
                    pkgs.gnumake
                    pkgs.shellcheck
                    pkgs.shfmt
                  ]
                  ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.chromium
                )
              } \
              --set-default PI_SKIP_VERSION_CHECK 1 \
              ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "--set PUPPETEER_SKIP_DOWNLOAD 1 --set-default PUPPETEER_EXECUTABLE_PATH ${lib.getExe pkgs.chromium}"}
          '';
        })
      ];

      home.file = {
        ".pi/agent/settings.json".source = (pkgs.formats.json { }).generate "pi-settings.json" (
          lib.recursiveUpdate {
            enableInstallTelemetry = false;
            collapseChangelog = true;
            quietStartup = true;

            npmCommand = [ "${pkgs.nodejs}/bin/npm" ];

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
              "npm:pi-web-fetch@1.1.0"
              "npm:pi-subagents@0.68.0"
              "npm:@juicesharp/rpiv-ask-user-question@2.10.1"
              "npm:@juicesharp/rpiv-todo@2.10.1"
            ];
          } root.config.piAgent.settings
        );

        ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

        ".pi/agent/skills/commit-style/SKILL.md".source = ./skills/commit-style/SKILL.md;
      };
    };
}
