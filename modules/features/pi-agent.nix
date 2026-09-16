root: {
  options.piAgent.settings = root.lib.mkOption {
    type = root.lib.types.attrsOf root.lib.types.json;
    default = { };
    description = ''
      Extra settings for ~/.pi/agent/settings.json, merged over the shared
      defaults; e.g. pin a default provider, model or thinking level.
    '';
  };

  config.flake.modules.homeManager.pi-agent =
    { pkgs, ... }:
    {
      home.sessionVariables.PI_SKIP_VERSION_CHECK = "1";

      home.packages = with pkgs; [
        unstable.pi-coding-agent
        git
        ripgrep
        fd
        jq
        nodejs
        python3
        uv
        coreutils
        gnumake
        shellcheck
        shfmt
      ];

      home.file = {
        ".pi/agent/settings.json".text = builtins.toJSON (
          {
            enableInstallTelemetry = false;
            quietStartup = true;
            defaultTools = [
              "read"
              "bash"
              "edit"
              "write"
              "grep"
              "find"
              "ls"
            ];
            enableSkillCommands = true;
            npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
            compaction = {
              enabled = true;
              reserveTokens = 16384;
              keepRecentTokens = 20000;
            };
            packages = [
              "npm:pi-web-fetch@1.1.0"
              "npm:pi-subagents@0.68.0"
            ];
          }
          // root.config.piAgent.settings
        );

        ".pi/agent/APPEND_SYSTEM.md".text = ''
          - Be plain and concise. No filler, preamble, or corporate tone.
          - Delegate coding work to pi-subagents when it's parallelizable, context-heavy, or clearly matches a specialist agent. Handle small, local edits directly. Before delegating, state in one line which agent and why.
          - Never fabricate context, file contents, command output, or parameter values. Gather information with tools first. Ask the user only when tools can't answer it. If you make a minor assumption, say so.
          - Confirm before destructive or irreversible actions.
          - Surface dead code, stale artifacts and small clearly-correct fixes in your reply and offer to do them; don't bury actionable findings in documentation.
          - Don't create documentation (READMEs, summary or changelog .md files) unless asked.
          - Comments: default to none. One line unless the context genuinely can't fit. No banners or headers comments. In code you're changing, drop comments that restate the code; leave unrelated comments alone.
        '';

        ".pi/agent/skills/commit-style/SKILL.md".text = ''
          ---
          name: commit-style
          description: Format git commit messages using Conventional Commits with a DCO sign-off line.
          ---
          # Commit style

          - Format: `type(scope): subject`.
          - `type` is one of feat, fix, docs, refactor, perf, test, chore, build, ci, revert.
          - `scope` is optional; use it for the affected package or module, lowercase.
          - `subject`: imperative mood, no trailing period, ≤ 72 chars.
          - Breaking change: append `!` after the type/scope and add a `BREAKING CHANGE:` footer.
          - Body wraps at 72 chars. Explain *why*, not *what* — the diff already shows what.
          - Every commit ends with a DCO sign-off: `Signed-off-by: Name <email>`. Use `git commit -s`.
          - Never write "WIP", "misc", or "updates" as the subject — ask what actually changed.
        '';

        ".pi/agent/skills/comment-policy/SKILL.md".text = ''
          ---
          name: comment-policy
          description: Enforce a strict minimal-comment policy when writing or reviewing code.
          ---
          # Comment policy

          - Default to zero new comments.
          - Comment only the *why*: non-obvious intent, invariants, or tradeoffs. Never restate what the code does.
          - Keep comments on a single line; multiline only for complex non-obvious context that cannot fit on one.
          - Delete comments that don't earn their keep: obvious restatements, section banners, headers, commented-out code.

          Before finishing an edit: is any comment I left shorter or gone?
        '';
      };
    };
}
