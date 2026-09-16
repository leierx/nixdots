vim.pack.add({
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("blink.cmp").setup({
  keymap = {
    preset = 'none',
    ['<C-space>'] = { 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'show', 'fallback' },

    ['<Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then return cmp.accept()
        else return cmp.select_and_accept() end
      end,
      'snippet_forward',
      'fallback'
    },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },
  sources = { default = { "lsp", "path", "snippets", "buffer" }, },
  signature = { enabled = true },
  completion = {
    menu = { draw = { treesitter = { "lsp" } } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    },
    accept = {
      auto_brackets = { enabled = true },
    },
    ghost_text = { enabled = true },
    trigger = { show_in_snippet = false },
  },
})
