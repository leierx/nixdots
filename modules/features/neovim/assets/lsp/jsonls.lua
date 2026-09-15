-- Merged over nvim-lspconfig's defaults (see lua/config/lsp.lua).
---@type vim.lsp.Config
return {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
