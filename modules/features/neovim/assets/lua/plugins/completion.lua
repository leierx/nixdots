vim.pack.add({
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/saghen/blink.cmp",            version = vim.version.range("1.*") },
})

require("blink.cmp").setup({
  snippets = { preset = "luasnip" },
  sources = { default = { "lsp", "path", "snippets", "buffer" }, },
  signature = { enabled = true },
  keymap = { preset = "enter", ["<C-y>"] = { "select_and_accept" }, },
  completion = {
    menu = {
      border = "none",
      draw = { treesitter = { "lsp" } },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    },
    accept = {
      auto_brackets = {
        enabled = true,
      },
    },
    ghost_text = {
      enabled = true,
      show_with_selection = true,
    },
  },
})
