vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

require("kanagawa").setup({
  -- Fix the blink.cmp groups kanagawa misses (it defines BlinkCmpLabelDetails,
  -- which blink never uses, and no LabelDescription/Source/DocSeparator).
  overrides = function(colors)
    local theme = colors.theme
    return {
      -- slightly brighter linenumbers
      LineNr = { fg = theme.ui.fg_dim },

      -- make MiniIndentscope match theme
      MiniIndentscopeSymbol = { link = "NonText" },
      MiniIndentscopeSymbolOff = { link = "NonText" },

      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },

      -- make popup/completion menus darker & more neutral (less "wave blue")
      Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
      PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
      PmenuSbar = { bg = theme.ui.bg_m1 },
      PmenuThumb = { bg = theme.ui.bg_p2 },
      PmenuKind = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p1 },
      PmenuExtra = { fg = theme.syn.comment, bg = theme.ui.bg_p1 },
    }
  end,
})

vim.cmd("colorscheme kanagawa")
