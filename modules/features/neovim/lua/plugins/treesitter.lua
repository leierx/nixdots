-- nvim-treesitter main only installs parsers (async, a no-op once done); highlighting is started below
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
