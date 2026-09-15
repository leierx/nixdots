-- Merged over nvim-lspconfig's defaults (see lua/config/lsp.lua); cmd,
-- filetypes, root_markers and the hint/codeLens settings are already its defaults.
---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      telemetry = { enable = false },
      workspace = {
        checkThirdParty = false,
        -- VIMRUNTIME + vim.pack plugins: covers vim.* and installed plugins.
        -- Indexing all of 'runtimepath' also pulls in the config itself and
        -- is noticeably slower (nvim-lspconfig#3189).
        library = {
          vim.env.VIMRUNTIME,
          vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt"),
        },
      },
    },
  },
}
