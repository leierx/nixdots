-- overrides live in after/lsp/<name>.lua, which wins over nvim-lspconfig's lsp/
vim.lsp.enable({
  "lua_ls",
  "nixd",
  "qmlls",
  "ts_ls",
  "html",
  "cssls",
  "marksman",
  "jsonls",
  "yamlls",
  "tofu_ls",
  "gopls",
})

-- LspAttach, not on_attach: a server's own on_attach (ts_ls) would replace ours
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Workspace diagnostics",
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    -- some clients support workspace diagnostics natively
    if client:supports_method("workspace/diagnostic", args.buf) then
      vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
    else
      require("workspace-diagnostics").populate_workspace_diagnostics(client, args.buf)
    end
  end,
})
