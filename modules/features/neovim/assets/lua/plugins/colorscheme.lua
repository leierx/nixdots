vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

require("kanagawa").setup({
  -- Fix the blink.cmp groups kanagawa misses (it defines BlinkCmpLabelDetails,
  -- which blink never uses, and no LabelDescription/Source/DocSeparator).
  overrides = function(colors)
    local theme = colors.theme
    return {
      BlinkCmpLabelDetail = { fg = theme.syn.comment },
      BlinkCmpLabelDescription = { fg = theme.syn.comment },
      BlinkCmpSource = { fg = theme.ui.special },
      BlinkCmpDocSeparator = { fg = theme.ui.float.fg_border },
    }
  end,
})

vim.cmd("colorscheme kanagawa")
