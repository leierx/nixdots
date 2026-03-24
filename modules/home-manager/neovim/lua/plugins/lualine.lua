return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      section_separators = "",
      component_separators = "",
    },

    sections = {
      lualine_c = {{ 'filename', path = 4 }},
      lualine_x = { "filetype", "lsp_status" },
    },
  },
}
