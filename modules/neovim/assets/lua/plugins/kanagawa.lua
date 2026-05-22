return {
  "rebelot/kanagawa.nvim",
  opts = {
    overrides = function(colors)
      local theme = colors.theme
      return {
        -- slightly brighter linenumbers
        LineNr = { fg = theme.ui.fg_dim },

        -- make MiniIndentscope match theme
        MiniIndentscopeSymbol = { link = "NonText" },
        MiniIndentscopeSymbolOff = { link = "NonText" },

        -- make popup/completion menus darker & more neutral (less "wave blue")
        Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
        PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
        PmenuSbar = { bg = theme.ui.bg_m1 },
        PmenuThumb = { bg = theme.ui.bg_p2 },
        PmenuKind = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p1 },
        PmenuExtra = { fg = theme.syn.comment, bg = theme.ui.bg_p1 },

        -- blink.cmp: keep linking to the (now fixed) Pmenu groups
        BlinkCmpMenu = { link = "Pmenu" },
        BlinkCmpMenuSelection = { link = "PmenuSel" },
        BlinkCmpMenuBorder = { link = "FloatBorder" },
        BlinkCmpScrollBarThumb = { link = "PmenuThumb" },
        BlinkCmpScrollBarGutter = { link = "PmenuSbar" },

        BlinkCmpLabel = { link = "Pmenu" },
        BlinkCmpLabelDeprecated = { link = "PmenuExtra" },
        BlinkCmpLabelMatch = { link = "Pmenu" },
        BlinkCmpLabelDetail = { link = "PmenuExtra" },
        BlinkCmpLabelDescription = { link = "PmenuExtra" },

        BlinkCmpKind = { link = "PmenuKind" },
        BlinkCmpSource = { link = "PmenuExtra" },

        BlinkCmpGhostText = { link = "NonText" },

        BlinkCmpDoc = { link = "NormalFloat" },
        BlinkCmpDocBorder = { link = "FloatBorder" },
        BlinkCmpDocSeparator = { link = "NormalFloat" },
        BlinkCmpDocCursorLine = { link = "Visual" },

        BlinkCmpSignatureHelp = { link = "NormalFloat" },
        BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
        BlinkCmpSignatureHelpActiveParameter = { link = "LspSignatureActiveParameter" },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    vim.cmd("colorscheme kanagawa")
  end,
}
