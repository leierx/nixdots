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
    go = { "goimports", "gofumpt" },
    qml = { "qmlformat" },
  },
  format_on_save = function(buf)
    if not vim.b[buf].skip_format then
      return { timeout_ms = 1000 }
    end
  end,
})

require("treesj").setup({ use_default_keymaps = false })

require("tiny-inline-diagnostic").setup()
