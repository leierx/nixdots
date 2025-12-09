return {
  { 'echasnovski/mini.pairs', config = true },
  {
    'echasnovski/mini.surround',
    opts = {
      mappings = {
        add = 'sa',
        delete = 'sd',
        replace = 'sr',
        find = '',
        find_left = '',
        highlight = '',
        update_n_lines = '',
        suffix_last = '',
        suffix_next = '',
      },
      silent = true,
    },
  },
  {
    "notjedi/nvim-rooter.lua",
    opts = {
      root_patterns = { ".git", "flake.nix" },
      outermost = true,
      command = "lcd",
    },
  },
  {
    "stevearc/resession.nvim",
    config = function()
      local rs = require("resession")

      rs.setup({
        options = {
          "buflisted", "bufhidden", "filetype",
          "modifiable", "readonly", "binary",
          "winfixheight", "winfixwidth", "scrollbind",
        },
        dir = "session",
      })


      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function() rs.save("last", { notify = false }) end,
      })
    end,
  },
}
