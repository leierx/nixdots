return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      telemetry = { enable = false },
      workspace = {
        library = vim.list_extend(
          { vim.env.VIMRUNTIME },
          vim.iter(vim.pack.get(nil, { info = false }))
            :map(function(p) return vim.fs.joinpath(p.path, "lua") end)
            :totable()
        ),
      },
    },
  },
}
