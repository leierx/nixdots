{
  flake.modules.homeManager.pi-agent =
    { pkgs, ... }:
    {
      home.sessionVariables.PI_SKIP_VERSION_CHECK = "1";

      home.packages = with pkgs; [
        pi-coding-agent
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
        ".pi/agent/settings.json".text = builtins.toJSON {
          enableInstallTelemetry = false;
          quietStartup = true;
          defaultProjectTrust = "ask";
          defaultProvider = "kimi-coding";
          defaultModel = "kimi-coding/kimi-k3";
          defaultThinkingLevel = "medium";
          modelThinkingLevels = {
            "kimi-coding/kimi-k3" = "medium";
          };
          subagents = {
            defaultProvider = "deepseek";
            defaultModel = "deepseek/deepseek-v4-flash";
            agentOverrides = {
              scout = {
                model = "deepseek/deepseek-v4-flash";
                thinking = "low";
              };
              delegate = {
                model = "deepseek/deepseek-v4-flash";
                thinking = "low";
              };
              researcher = {
                model = "deepseek/deepseek-v4-flash";
                thinking = "medium";
              };
              worker = {
                model = "kimi-coding/kimi-k3";
                thinking = "high";
              };
              reviewer = {
                model = "kimi-coding/kimi-k3";
                thinking = "high";
              };
              evidence-auditor = {
                model = "kimi-coding/kimi-k3";
                thinking = "high";
              };
              oracle = {
                model = "kimi-coding/kimi-k3";
                thinking = "high";
              };
            };
          };
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
            "npm:pi-subagents@0.67.0"
          ];
        };

        ".pi/agent/AGENTS.md".text = ''
          # Global agent instructions

          Cross-project working preferences. Project `AGENTS.md` files win where they disagree.

          ## Reading and searching

          - Use `read` for files, not `cat`/`head`/`tail`. It truncates and paginates.
          - Use `grep` and `find` for search; use `ls` for listing.
          - Reserve `bash` for actual commands. Redirect large output to a file and grep it.

          ## Editing

          - Use `edit` for targeted changes, `write` for new files or full rewrites.
          - Batch multiple edits to one file into a single `edit` call.

          ## Git safety

          - `git checkout <path>` restores from the index, not HEAD. Check `git diff --cached --name-only` first, or use `git restore --source=HEAD <path>`.
          - Use `git worktree add` to inspect another revision instead of `git stash`.

          ## Delegation

          - For unfamiliar codebases, delegate to `scout` subagents in parallel.
          - For mechanical work, define an invariant first, then delegate.
          - Send reviews to a fresh-context `reviewer`, not the author.

          ## Style

          - Be concise. Report conclusions and evidence, not narration.
          - Comments explain *why*, never *what*.
          - Commits: Conventional Commits, signed off with `git commit -s`.
        '';

        ".pi/agent/skills/commit-style.md".text = ''
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

        ".pi/agent/skills/comment-policy.md".text = ''
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