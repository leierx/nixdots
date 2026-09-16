vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

require("kanagawa").setup({
  -- Fix the blink.cmp groups kanagawa misses (it defines BlinkCmpLabelDetails,
  -- which blink never uses, and no LabelDescription/Source/DocSeparator).
  overrides = function(colors)
    local theme = colors.theme
    local palette = colors.palette
    return {
      -- slightly brighter linenumbers
      LineNr = { fg = theme.ui.fg_dim },

      -- make MiniIndentscope match theme
      MiniIndentscopeSymbol = { link = "NonText" },
      MiniIndentscopeSymbolOff = { link = "NonText" },

      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },

      Pmenu = { fg = theme.ui.shade0, bg = "none" },
      PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
      PmenuSbar = { bg = theme.ui.bg_m1 },
      PmenuThumb = { bg = theme.ui.bg_p2 },
      BlinkCmpMenu = { bg = theme.ui.bg },
      BlinkCmpMenuBorder = { bg = theme.ui.bg, fg = palette.crystalBlue },
      BlinkCmpDoc = { bg = theme.ui.bg },
      BlinkCmpDocBorder = { bg = theme.ui.bg, fg = palette.crystalBlue },
    }
  end,
})

vim.cmd("colorscheme kanagawa")
