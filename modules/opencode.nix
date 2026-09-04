{
  modules.homeManager.opencode =
    { pkgs, ... }:
    {
      home.sessionVariables.OPENCODE_DISABLE_LSP_DOWNLOAD = "true";

      programs.opencode = {
        enable = true;

        extraPackages = with pkgs; [
          nixd
          rust-analyzer
          gopls
          pyright
          typescript
          typescript-language-server
          bash-language-server
          yaml-language-server
          vscode-langservers-extracted
          lua-language-server
          terraform-ls
          clang-tools
        ];

        settings = {
          autoupdate = false; # Nix owns the package

          plugin = [ "@dietrichgebert/ponytail" ]; # minimal-code ruleset

          lsp = {
            nixd = {
              command = [ "nixd" ];
            };
            rust = {
              command = [ "rust-analyzer" ];
            };
            gopls = {
              command = [ "gopls" ];
            };
            pyright = {
              command = [
                "pyright-langserver"
                "--stdio"
              ];
            };
            typescript = {
              command = [
                "typescript-language-server"
                "--stdio"
              ];
            };
            bash = {
              command = [
                "bash-language-server"
                "start"
              ];
            };
            yaml-ls = {
              command = [
                "yaml-language-server"
                "--stdio"
              ];
            };
            eslint = {
              command = [
                "vscode-eslint-language-server"
                "--stdio"
              ];
            };
            "lua-ls" = {
              command = [ "lua-language-server" ];
            };
            terraform = {
              command = [
                "terraform-ls"
                "serve"
              ];
            };
            clangd = {
              command = [ "clangd" ];
            };
          };
        };

        context = ''
          # Comment policy
          - Default to zero new comments.
          - Comment only the *why*: non-obvious intent, invariants, or tradeoffs. Never restate what the code does.
          - Keep comments on a single line; multiline only for complex non-obvious context that cannot fit on one.
          - Delete comments that don't earn their keep: obvious restatements, section banners, headers, commented-out code.

          Before finishing an edit: is any comment I left shorter or gone?
        '';

        agents.assistant = ''
          ---
          description: Zero-tool agent for general knowledge and conversation.
          mode: primary
          permission:
            "*": deny
          ---

          <role>
          You are a conversational assistant with no tools. You answer from training knowledge — chat, explain, reason, brainstorm. Nothing else.
          </role>

          <no_tools>
          - You have NO tools available. Do not attempt to call any. Do not pretend to search the web, read files, run code, or fetch URLs.
          - If a request genuinely needs live data, file access, or code execution, say so in one line and suggest switching agents (`build`, `plan`, or a research agent).
          - If a request is after your training cutoff, say so plainly instead of guessing.
          </no_tools>

          <response_style>
          - Start with the answer. No openers like "Great question!", "Certainly!", or "Happy to help!".
          - Match the question's depth: one-liner in, one-liner out. Don't pad short answers into essays.
          - Use markdown only when it helps — code blocks for code, lists only for genuine lists.
          - No emojis unless the user uses them first.
          - No unprompted caveats, disclaimers, or safety boilerplate.
          </response_style>

          <honesty>
          - "I don't know" is a valid answer. Prefer it to speculation.
          - Distinguish confident facts from best guesses when it matters.
          - Never fabricate citations, URLs, quotes, statistics, or people.
          </honesty>
        '';
      };
    };
}
