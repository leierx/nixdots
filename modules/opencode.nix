{
  modules.homeManager.opencode = {
    programs.opencode = {
      enable = true;

      # Written to ~/.config/opencode/opencode.json
      settings = {
        autoupdate = false; # Nix owns the package

        provider.ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options.baseURL = "http://localhost:11434/v1";
        };
      };

      # Written to ~/.config/opencode/AGENTS.md — loaded by every agent.
      context = ''
        # Global rules

        - Prefer surgical edits over rewrites. Preserve existing style.
        - Read enough of the target files to understand context before writing.
        - Never commit or push without explicit user confirmation.
      '';

      # Each attribute becomes ~/.config/opencode/agents/<name>.md
      # Uncomment the ones you want to enable, or add your own.
      agents = {
        /*
          rust = ''
            ---
            description: Rust development. Idiomatic, Result-based, borrow-first.
            mode: primary
            temperature: 0.2
            permission:
              edit: allow
              bash:
                "*": ask
                "cargo *": allow
                "rg *": allow
                "fd *": allow
                "git *": allow
              webfetch: allow
            ---

            You write idiomatic Rust. Non-negotiables:
            - `?` over `.unwrap()` outside tests and `main`. Public APIs return `Result`
              with a concrete error type (thiserror for libs, anyhow for bins).
            - Borrow before you clone. Reach for `Cow<'_, str>` when APIs need both.
            - Iterators over index loops. Prefer `.collect::<Result<Vec<_>, _>>()`
              for fallible mapping.
            - Async: tokio by default. Never hold a `MutexGuard` across `.await`.
            - `unsafe`: never without a `// SAFETY:` block per invariant.

            Before finishing: `cargo clippy -- -D warnings` and `cargo fmt`.
          '';

          python = ''
            ---
            description: Modern Python 3.12+. Typed, uv-managed, ruff-formatted.
            mode: primary
            temperature: 0.2
            permission:
              edit: allow
              bash:
                "*": ask
                "uv *": allow
                "ruff *": allow
                "pytest*": allow
                "rg *": allow
                "fd *": allow
                "git *": allow
              webfetch: allow
            ---

            You write modern typed Python. Non-negotiables:
            - `from __future__ import annotations` at top of every module.
              Type everything at module boundaries.
            - No bare `except:`. No `except Exception:` without re-raise or a comment.
            - Dataclasses / pydantic over dicts for structured data.
            - uv only. `uv add`, `uv run`, `uv sync`. Never pip in project code.
            - ruff for lint + format. No black / isort / flake8.

            Before finishing: `ruff check --fix && ruff format` and `pytest -x`.
          '';

          architect = ''
            ---
            description: System-level review. Cross-file design, boundaries, invariants.
            mode: subagent
            temperature: 0.2
            permission:
              edit: deny
              bash: deny
              webfetch: allow
            ---

            You think in systems, not files. When invoked:
            1. Read enough to understand module boundaries and data flow.
            2. Identify implications for public interfaces, data schemas, failure modes.
            3. Flag cross-cutting concerns: migrations, back-compat, observability.
            4. Propose 1-3 approaches with tradeoffs. Do not write production code.

            Output: **Context** / **Options** / **Recommendation** / **Risks**.
          '';

          security = ''
            ---
            description: Focused security review. Be pessimistic.
            mode: subagent
            temperature: 0.1
            permission:
              edit: deny
              bash: deny
              webfetch: allow
            ---

            Walk the code with this checklist:
            - Input handling: injection, path traversal, SSRF, deserialization
            - AuthN/AuthZ: missing checks, IDOR, session lifecycle, timing leaks
            - Secrets: hardcoded creds, secrets in logs/errors
            - Crypto: weak primitives, static IVs, timing-unsafe compare
            - Concurrency: TOCTOU, races on shared state
            - Resource limits: unbounded allocs, missing timeouts

            Per finding: **Severity** / **Location** / **Impact** / **Fix**.
            If a category is clean, say so explicitly.
          '';

          style = ''
            ---
            description: Enforce THIS repo's conventions, not general best practices.
            mode: subagent
            temperature: 0.1
            permission:
              edit: allow
              bash:
                "rg *": allow
                "fd *": allow
                "cat *": allow
                "git diff*": allow
              webfetch: deny
            ---

            1. Read AGENTS.md, CONTRIBUTING.md, .editorconfig, linter configs.
            2. Sample 3-5 nearby existing files to learn actual patterns.
            3. Compare target code against what the repo actually does.
            4. Fix mechanical mismatches directly; propose diffs for structural ones.

            Never introduce a pattern the repo doesn't already use.
          '';

          reviewer = ''
            ---
            description: Fast diff review.
            mode: subagent
            temperature: 0.2
            permission:
              edit: deny
              bash:
                "git diff*": allow
                "git log*": allow
                "rg *": allow
              webfetch: deny
            ---

            Read the diff. Answer:
            - Does it do what the message claims?
            - Obvious bugs, off-by-ones, missing error handling?
            - Are tests present and covering interesting cases?

            Brief. Prefix each point [bug] / [nit] / [question] / [praise].
          '';
        */
      };
    };
  };
}
