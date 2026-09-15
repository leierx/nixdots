-- Merged over nvim-lspconfig's defaults (see lua/config/lsp.lua).
---@type vim.lsp.Config
return {
  -- lspconfig's list plus yaml.ansible (config/filetypes.lua maps inventory dirs to it)
  filetypes = { "yaml", "yaml.ansible", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  settings = {
    yaml = {
      format = { enable = false },
      -- Use the local SchemaStore plugin instead of yamlls' built-in fetcher.
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
