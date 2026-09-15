vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

-- nvim-treesitter "main" (the rewrite): the plugin only ships parsers and
-- queries; highlighting is Neovim's own vim.treesitter.start(). Parser
-- installation shells out to the `tree-sitter` CLI and a C compiler, both
-- provided by the nix module. install() is async and a no-op once done.
require("nvim-treesitter").install({
  "bash",
  "css",
  "diff",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "jsonc",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "nix",
  "query",
  "regex",
  "scss",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Start treesitter highlighting where a parser exists",
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
