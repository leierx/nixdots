local fzf_lua = require("fzf-lua")
local code_action = require("tiny-code-action")
local grep_defaults = require("fzf-lua.defaults").defaults.grep

fzf_lua.setup({
  -- agent docs restate the code they describe and drown out real matches
  grep = {
    rg_opts = "-g '!AGENTS.md' " .. grep_defaults.rg_opts,
  },
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
