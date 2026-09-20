-- nvim-treesitter "main" only ships parsers/queries; highlighting is Neovim's
-- vim.treesitter.start(). install() shells out to the tree-sitter CLI and a C
-- compiler (both from the nix module) and is async, a no-op once done.
require("nvim-treesitter").install({
  "bash",
  "css",
  "diff",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "nix",
  "qmldir",
  "qmljs",
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
