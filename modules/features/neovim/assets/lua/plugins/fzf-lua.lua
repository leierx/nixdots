vim.pack.add({
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/rachartier/tiny-code-action.nvim",
})

local fzf_lua = require("fzf-lua")
local code_action = require("tiny-code-action")

fzf_lua.setup({
  fzf_opts = {
    ["--cycle"] = true,
  },
  keymap = {
    fzf = {
      true,
      ["ctrl-q"] = "select-all+accept", -- Use <c-q> to select all items and add them to the quickfix list
    },
  },
})

code_action.setup({ picker = "fzf-lua" })
