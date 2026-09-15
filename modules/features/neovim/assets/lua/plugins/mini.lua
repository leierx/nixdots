vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

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
