vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.nvim", version = "stable" },
})

-- icons, replace nvim_web_devicons
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("mini.cursorword").setup()
require("mini.pairs").setup()

require("mini.surround").setup({
  mappings = { find = "", find_left = "", highlight = "", suffix_last = "", suffix_next = "" },
})

require("mini.indentscope").setup({
  draw = { animation = function() return 0 end },
  mappings = { object_scope = "", object_scope_with_border = "", goto_top = "", goto_bottom = "" },
  symbol = "│",
  options = { indent_at_cursor = false },
})

require("mini.diff").setup({
  view = { style = "number" },
  mappings = { apply = "", reset = "", textobject = "", goto_first = "", goto_last = "", goto_next = "", goto_prev = "" },
})

require("mini.files").setup({
  content = {
    filter = nil,
    sort = nil,
  },

  mappings = {
    close = 'q',
    go_in = 'l',
    go_in_plus = 'L',
    go_out = 'h',
    go_out_plus = 'H',
    mark_goto = "'",
    mark_set = 'm',
    reset = '<BS>',
    reveal_cwd = '@',
    show_help = 'g?',
    synchronize = '=',
    trim_left = '<',
    trim_right = '>',
  },

  options = {
    permanent_delete = true,
    use_as_default_explorer = false,
    lsp_timeout = 1000,
  },

  windows = {
    max_number = math.huge,
    preview = false,
    width_focus = 50,
    width_nofocus = 15,
    width_preview = 25,
  },
})
