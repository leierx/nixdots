return {
  { "nvim-mini/mini.cursorword", version = "*", config = true },
  { "nvim-mini/mini.pairs", version = "*", config = true },
  { "nvim-mini/mini.splitjoin", version = "*", opts = { mappings = { toggle = "", split = "", join = "" }, } },
  {
    "nvim-mini/mini.surround",
    version = "*",
    init = function() vim.keymap.set("n", "s", "<Nop>", { desc = "use `cl` or `r`" }) end,
    opts = { mappings = { find = "", find_left = "", highlight = "", suffix_last = "", suffix_next = "" } },
  },
  {
    "nvim-mini/mini.indentscope",
    version = "*",
    opts = {
      draw = { animation = function() return 0 end }, -- disable distracting animation
      mappings = { object_scope = "", object_scope_with_border = "", goto_top = "", goto_bottom = "" },
      symbol = "│",
      options = { indent_at_cursor = false },
    }
  },
  {
    "nvim-mini/mini.diff",
    version = "*",
    lazy = false, -- does not load without this...
    opts = {
      view = { style = "number" },
      mappings = { apply = "", reset = "", textobject = "", goto_first = "", goto_last = "", goto_next = "", goto_prev = "" },
    },
    keys = { { "gh", [[<cmd>lua require("mini.diff").toggle_overlay()<CR>]], desc = "MiniDiff: toggle overlay" } },
  },
}
