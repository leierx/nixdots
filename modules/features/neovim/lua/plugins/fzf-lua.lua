local fzf_lua = require("fzf-lua")
local code_action = require("tiny-code-action")

fzf_lua.setup({
  fzf_opts = {
    ["--cycle"] = true,
  },
  keymap = {
    fzf = {
      true,
      ["ctrl-q"] = "select-all+accept",
    },
  },
})

code_action.setup({ picker = "fzf-lua" })
