require("gitsigns").setup()

require("lualine").setup({
  options = {
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_c = { { "filename", path = 4 } },
    lualine_x = { "searchcount", "filetype", "lsp_status" },
  },
})

require("conform").setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
  },
  format_on_save = { timeout_ms = 1000 },
})

require("treesj").setup({ use_default_keymaps = false })

require("tiny-inline-diagnostic").setup()
vim.diagnostic.config()
