vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

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
