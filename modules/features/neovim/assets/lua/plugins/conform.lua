vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})
