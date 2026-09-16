return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      telemetry = { enable = false },
      workspace = { library = { vim.env.VIMRUNTIME } }
    },
  },
}
