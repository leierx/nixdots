local bubbles_theme = {
  normal = {
    a = { fg = '#080808', bg = '#d183e8' },
    b = { fg = '#c6c6c6', bg = '#303030' },
    c = { fg = '#c6c6c6' },
  },

  insert = { a = { fg = '#080808', bg = '#80a0ff' } },
  visual = { a = { fg = '#080808', bg = '#79dac8' } },
  replace = { a = { fg = '#080808', bg = '#ff5189' } },

  inactive = {
    a = { fg = '#c6c6c6', bg = '#080808' },
    b = { fg = '#c6c6c6', bg = '#080808' },
    c = { fg = '#c6c6c6' },
  },
}

return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      theme = "wave",
      background = { dark = "wave", light = "lotus" },
      overrides = function(colors)
        return { LineNr = { fg = colors.theme.ui.fg_dim } } -- slightly brighter linenumbers
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = bubbles_theme,
        component_separators = '',
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_a = {{ 'mode', separator = { left = '' }, right_padding = 2 }},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {},
        lualine_z = {{ 'location', separator = { right = '' }, left_padding = 2 }}
      },
    },
  },
  { 'echasnovski/mini.cursorword', config = true },
  {
    "rcarriga/nvim-notify",
    config = function() vim.notify = require("notify") end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = { "MunifTanjim/nui.nvim" }
  },
}
